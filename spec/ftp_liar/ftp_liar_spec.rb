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

        it { expect( @ftp_liar.pwd ).to eq("/") }
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
        before(:all) { @ftp_liar.mkdir("/hip") }
        after(:all) { @ftp_liar.rmdir("/hip") }

        describe "when path is relative" do
          before(:all) do
            FileUtils.touch("/tmp/.ftp_liar/foo.file")
            FileUtils.touch("/tmp/.ftp_liar/hip/bar.file")
          end

          it { expect( @ftp_liar.delete("foo.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/foo.file") == false } }
          it { expect( @ftp_liar.delete("hip/bar.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/hip/bar.file") == false } }
        end

        describe "when path is absolute" do
          before(:all) do
            FileUtils.touch("/tmp/.ftp_liar/foo.file")
            FileUtils.touch("/tmp/.ftp_liar/hip/bar.file")
          end

          it { expect( @ftp_liar.delete("/foo.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/foo.file") == false } }
          it { expect( @ftp_liar.delete("/hip/bar.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/hip/bar.file") == false } }
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

      it { expect{ @ftp_liar.get("/") }.to raise_error(Errno::EISDIR) }

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
          it { expect( @ftp_liar.get("foo", "/tmp/foo") ).to satisfy { File.exist?("/tmp/foo") == true } }
        end

        pending("Add examples with absolute path")
      end
    end
  end

  describe "login" do
    before(:each) do
      @ftp_liar = FTPLiar::FTPLiar.new
      @ftp_liar.close
    end

    it { expect{ @ftp_liar.login("foo") }.to raise_error(Net::FTPPermError, "530 User cannot log in.") }
    it { expect{ @ftp_liar.login(passwd = "bar") }.to raise_error(Net::FTPPermError, "530 User cannot log in.") }
    it { expect{ @ftp_liar.login("anonymous") }.to change{@ftp_liar.closed?}.from(true).to(false) }
    it { expect{ @ftp_liar.login() }.to change{@ftp_liar.closed?}.from(true).to(false) }
    it { expect{ @ftp_liar.login('foo', 'bar') }.to change{@ftp_liar.closed?}.from(true).to(false) }
  end

  describe "mkdir" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.mkdir("bar") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }
      after(:all) do
        @ftp_liar.rmdir("/bas")
        @ftp_liar.rmdir("/bar")
        @ftp_liar.rmdir("/..bas")
      end

      it { expect{ @ftp_liar.mkdir("../../tmp") }.to raise_error(Net::FTPPermError, "550") }
      it { expect{ @ftp_liar.mkdir("/") }.to raise_error(Net::FTPPermError, "550") }
      it { expect( @ftp_liar.mkdir("/bas") ).to eq "/bas" }
      it { expect( @ftp_liar.mkdir("bar") ).to eq "bar" }
      it { expect( @ftp_liar.mkdir("..bas") ).to eq "..bas" }
      describe "into bas" do
        before(:all) { @ftp_liar.chdir("bas") }
        after(:all) { @ftp_liar.rmdir("foo") }

        it { expect( @ftp_liar.mkdir("foo") ).to eq "foo" }
      end
    end
  end

  describe "nlst" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.nlst("bar") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.mkdir("/foo")
        FileUtils.touch("/tmp/.ftp_liar/foo.file")
        FileUtils.touch("/tmp/.ftp_liar/foo/foo.file")
        FileUtils.touch("/tmp/.ftp_liar/foo/bar.file")
      end

      after(:all) do
        FileUtils.rm_rf("/tmp/.ftp_liar/foo")
        FileUtils.rm_rf("/tmp/.ftp_liar/foo.file")
      end

      it { expect{ @ftp_liar.nlst("..") }.to raise_error(Net::FTPPermError, "550") }
      describe "from foo directory" do
        before(:all) { @ftp_liar.chdir("foo") }

        it { expect( @ftp_liar.nlst(".") ).to match_array(["foo.file", "bar.file"]) }
        it { expect( @ftp_liar.nlst("foo.file") ).to match_array(["foo.file"]) }
        it { expect( @ftp_liar.nlst("bar.file") ).to match_array(["bar.file"]) }
        it { expect( @ftp_liar.nlst("..") ).to match_array(["foo.file", "foo"]) }
        it { expect( @ftp_liar.nlst("/") ).to match_array(["foo.file", "foo"]) }
        it { expect( @ftp_liar.nlst("../foo.file") ).to match_array(["../foo.file"]) }
        it { expect{ @ftp_liar.nlst("../../../foo.file") }.to raise_error(Net::FTPPermError, "550") }
      end
    end
  end

  describe "put/putbinaryfile/puttextfile" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.put("bar") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.mkdir("foo")
        FileUtils.touch("/tmp/foo.file")
      end
      after(:all) { @ftp_liar.rmdir("foo") }

      it { expect{ @ftp_liar.put("/tmp") }.to raise_error(Errno::EISDIR) }
      it { expect{ @ftp_liar.put("/tmp/bar.file") }.to raise_error(Errno::ENOENT) }
      it { expect{ @ftp_liar.put("/tmp/foo.file", "foo") }.to raise_error(Net::FTPPermError, "550") }
      it { expect{ @ftp_liar.put("/tmp/foo.file", "/") }.to raise_error(Net::FTPPermError, "550") }
      it { expect{ @ftp_liar.put("/tmp/foo.file", "..") }.to raise_error(Net::FTPPermError, "550") }
      it { expect{ @ftp_liar.put("/tmp/foo.file", "../../home") }.to raise_error(Net::FTPPermError, "550") }

      describe "withoud remotefile" do
        after(:all) { @ftp_liar.delete("foo.file") }
        it { expect( @ftp_liar.put("/tmp/foo.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/foo.file") } }
      end

      describe "relative path" do
        before(:all) { @ftp_liar.chdir('foo') }
        after(:all) do
          @ftp_liar.delete("foo.file")
          @ftp_liar.chdir('..')
          @ftp_liar.delete("foo.file")
        end

        it { expect( @ftp_liar.put("/tmp/foo.file", "foo.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/foo/foo.file") == true } }
        it { expect( @ftp_liar.put("/tmp/foo.file", "../foo.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/foo.file") == true } }
      end

      describe "absolute path" do
        before(:all) { @ftp_liar.chdir('foo') }
        after(:all) do
          @ftp_liar.delete("foo.file")
          @ftp_liar.chdir('..')
          @ftp_liar.delete("foo.file")
        end

        it { expect( @ftp_liar.put("/tmp/foo.file", "/foo/foo.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/foo/foo.file") } }
        it { expect( @ftp_liar.put("/tmp/foo.file", "/foo.file") ).to satisfy { |v| File.exist?("/tmp/.ftp_liar/foo.file") } }
      end
    end
  end

  describe "pwd" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.pwd }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }

      it { expect( @ftp_liar.getdir ).to eq "/" }

      describe "from subfolder" do
        before(:all) do
          @ftp_liar.mkdir("foo")
          @ftp_liar.chdir("foo")
        end
        after(:all) do
          @ftp_liar.chdir("..")
          @ftp_liar.rmdir("foo")
        end

        it { expect( @ftp_liar.pwd ).to eq "/foo" }
      end
    end
  end

  describe "rmdir" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.rmdir("foo") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.mkdir("foo")
        @ftp_liar.mkdir("bar")
        @ftp_liar.mkdir("bas")
        @ftp_liar.mkdir("foo/bar")
        @ftp_liar.mkdir("foo/bas")
        FileUtils.touch("/tmp/.ftp_liar/foo.file")
        @ftp_liar.chdir("foo")
      end
      after(:all) do
        @ftp_liar.chdir("/")
        @ftp_liar.delete("foo.file")
        @ftp_liar.rmdir("foo")
      end

      it { expect{ @ftp_liar.rmdir("/foo.file") }.to raise_error(Net::FTPPermError, "550") }
      it { expect( @ftp_liar.rmdir("/bar") ).to be nil }
      it { expect( @ftp_liar.rmdir("/foo/bas") ).to be nil }
      it { expect( @ftp_liar.rmdir("bar") ).to be nil }
      it { expect( @ftp_liar.rmdir("../bas") ).to be nil }
    end
  end
end
