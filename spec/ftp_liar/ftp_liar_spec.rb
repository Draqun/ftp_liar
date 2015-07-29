require 'spec_helper'

RSpec.describe FTPLiar::FTPLiar do
  describe "initializer" do
    it { expect{ FTPLiar::FTPLiar.new('127.0.0.1', user = 'foo') }.to raise_error(Net::FTPPermError, "530 User cannot log in.") }
    it { expect{ FTPLiar::FTPLiar.new('127.0.0.1', passwd = 'bar') }.to raise_error(Net::FTPPermError, "530 User cannot log in.") }

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
      expect{ @ftp_liar.binary = false }.to change{@ftp_liar.binary}.from(true).to(false)
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

      describe "should raise error" do
        it { expect{ @ftp_liar.chdir("/tmp/.ftp_liar") }.to raise_error(Net::FTPPermError, "500") }
        it { expect{ @ftp_liar.chdir("../../tmp") }.to raise_error(Net::FTPPermError, "500") }
        it { expect{ @ftp_liar.chdir("/../../tmp") }.to raise_error(Net::FTPPermError, "500") }
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

  describe "connect" do
    before(:all) do
      @ftp_liar = FTPLiar::FTPLiar.new
      @ftp_liar.close
    end

    it "should be true after method connect" do
      expect{ @ftp_liar.connect("127.0.0.1") }.to change{@ftp_liar.closed?}.from(true).to(false)
    end
  end

  describe "delete" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.delete("foo") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }

      describe "should raise Net::FTPPermError when file not exist" do
        it { expect{ @ftp_liar.delete("bar") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.delete("/bar") }.to raise_error(Net::FTPPermError, "550") }
      end

      describe "should raise Net::FTPPermError when target is not in ftp_liar temporary directory" do
        it { expect{ @ftp_liar.delete("../../bar") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.delete("/../../bar") }.to raise_error(Net::FTPPermError, "550") }
      end

      describe "should delete file" do
        before(:each) { FileUtils.touch("/tmp/.ftp_liar/foo") }

        it "should delete file, when path is relative" do
          @ftp_liar.delete("foo")
          expect( File.exist?("/tmp/.ftp_liar/foo") ).to be false
        end

        it "should delete file, when path is absolute" do
          @ftp_liar.delete("/foo")
          expect( File.exist?("/tmp/.ftp_liar/foo") ).to be false
        end
      end
    end
  end

  describe "get/getbinaryfile/gettextfile" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.delete("foo") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }

      describe "should raise Net::FTPPermError when file not exist" do
        it { expect{ @ftp_liar.get("bar") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.get("/bar") }.to raise_error(Net::FTPPermError, "550") }
      end

      describe "should raise Net::FTPPermError when target is not in ftp_liar temporary directory" do
        it { expect{ @ftp_liar.get("../../bar") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.get("/../../bar") }.to raise_error(Net::FTPPermError, "550") }
      end

      describe "file exist on server" do
        before(:each) { FileUtils.touch("/tmp/.ftp_liar/foo") }
        after(:each) { FileUtils.rm("/tmp/.ftp_liar/foo") }

        describe "should raise Errno::ENOENT when dir in local computer does not exist" do
          it { expect{ @ftp_liar.get("foo", "/tmp/bas/foo") }.to raise_error(Errno::ENOENT) }
        end

        describe "should raise Errno::EISDIR when localpath is dir" do
          it { expect{ @ftp_liar.get("foo", "/tmp") }.to raise_error(Errno::EISDIR) }
        end

        describe "should copy file from ftp using relative path" do
          after(:all) { FileUtils.rm("/tmp/foo") }
          it do
            @ftp_liar.get("foo", "/tmp/foo")
            expect( File.exist?("/tmp/foo") ).to be true
          end
        end
      end
    end
  end
end
