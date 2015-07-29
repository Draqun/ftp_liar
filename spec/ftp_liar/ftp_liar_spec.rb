require 'spec_helper'

RSpec.describe FTPLiar::FTPLiar do
  describe "initializer" do
    it "should raise Net::FTPPermError" do
      expect{ FTPLiar::FTPLiar.new('127.0.0.1', user = 'foo') }.to raise_error(Net::FTPPermError, "530 User cannot log in.")
    end

    it "should raise Net::FTPPermError" do
      expect{ FTPLiar::FTPLiar.new('127.0.0.1', passwd = 'bar') }.to raise_error(Net::FTPPermError, "530 User cannot log in.")
    end

    describe "work without any data" do
      before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }

      it "should create directory in temporary dir" do
        expect( Dir.exist?( File.join(Dir.tmpdir, '.ftp_liar') ) ).to be true
      end
    end

    describe "work with data" do
      before(:all) { @ftp_liar = FTPLiar::FTPLiar.new('127.0.0.1', 'foo', 'bar') }

      it "should create directory in temporary dir" do
        expect( Dir.exist?( File.join(Dir.tmpdir, '.ftp_liar') ) ).to be true
      end
    end
  end

  describe "finalizer" do
    before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }

    it "should remove directory in temporary dir" do
      @ftp_liar.finalize(nil)
      expect( Dir.exist?( File.join(Dir.tmpdir, '.ftp_liar') ) ).to be false
    end
  end

  describe "binary" do
    before(:each) { @ftp_liar = FTPLiar::FTPLiar.new }

    it "should be set default as true" do
      expect( @ftp_liar.binary ).to be true
    end


    it "set variable as false" do
      expect( lambda { @ftp_liar.binary = false } ).to change{@ftp_liar.binary}.from(true).to(false)
    end
  end

  describe "chdir" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it "should raise Net::FTPPermError" do
        expect{ @ftp_liar.chdir("/") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.")
      end
    end

    describe "when is connected" do
      before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }

      describe "when using \"/\" as path it should go to temporary directory" do
        before(:all) { @ftp_liar.chdir("/") }

        it { expect( @ftp_liar.pwd ).to eq("/tmp/.ftp_liar") }
      end

      it "should raise error" do
        expect{ @ftp_liar.chdir("/tmp/.ftp_liar") }.to raise_error(Net::FTPPermError, "500")
      end
    end
  end

  describe "closed? and close" do
    before(:each) { @ftp_liar = FTPLiar::FTPLiar.new }

    it { expect( @ftp_liar.closed? ).to be false }
    it { expect( @ftp_liar.close ).to eq "" }
  end

  describe "closed? after close" do
    before(:all) do
      @ftp_liar = FTPLiar::FTPLiar.new
      @ftp_liar.close
    end

    it { expect( @ftp_liar.closed? ).to be true }
  end

  describe "delete" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it "should raise Net::FTPPermError" do
        expect{ @ftp_liar.delete("foo") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.")
      end
    end
    #before(:all) do
    #  @ftp_liar = FTPLiar::FTPLiar.new
    #  FileUtils.touch
    #end
  end
end
