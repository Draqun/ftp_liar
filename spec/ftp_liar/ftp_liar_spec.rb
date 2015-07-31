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

  describe "open" do
    it { expect( FTPLiar::FTPLiar.open('127.0.0.1') ).to be_truthy }
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
    before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }

    it { expect{ @ftp_liar.close }.to change{ @ftp_liar.closed? }.from(false).to(true) }
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

  describe "quit" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.quit }.to raise_error(Errno::EPIPE, "Broken pipe") }
    end

    describe "when is connected" do
      before(:all) { @ftp_liar = FTPLiar::FTPLiar.new }

      it { expect{ @ftp_liar.quit }.to change{ @ftp_liar.closed? }.from(false).to(true) }
    end
  end

  describe "rename" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.close
      end

      it { expect{ @ftp_liar.rename("foo", "bar") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.mkdir("hip")

        %w( foo bar bas ).each do |i|
          @ftp_liar.mkdir(i)
          @ftp_liar.mkdir("#{i}by-foo")
          @ftp_liar.mkdir("hip/#{i}")
          @ftp_liar.mkdir("hip/#{i}by-foo")

          FileUtils.touch("/tmp/.ftp_liar/#{i}.file")
          FileUtils.touch("/tmp/.ftp_liar/#{i}by-foo.file")
          FileUtils.touch("/tmp/.ftp_liar/hip/#{i}.file")
          FileUtils.touch("/tmp/.ftp_liar/hip/#{i}by-foo.file")
        end
      end

      after(:all) do
        %w( foo bar bas ).each do |i|
          @ftp_liar.delete("#{i}by.file")
          @ftp_liar.delete("#{i}by-bar.file")
          @ftp_liar.delete("hip/#{i}by.file")
          @ftp_liar.delete("hip/#{i}by-bar.file")

          @ftp_liar.rmdir("#{i}by")
          @ftp_liar.rmdir("#{i}by-bar")
          @ftp_liar.rmdir("hip/#{i}by")
          @ftp_liar.rmdir("hip/#{i}by-bar")
        end

        @ftp_liar.rmdir("hip")
      end

      describe "when one of paths is \"/\"" do
        it { expect{ @ftp_liar.rename("/", "hip") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.rename("/", "/hip") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.rename("foo", "/") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.rename("/foo", "/") }.to raise_error(Net::FTPPermError, "550") }
      end
      describe "when one of paths does not indicate to ftp directory" do
        it { expect{ @ftp_liar.rename("../foo", "bar") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.rename("/../../foo", "bar") }.to raise_error(Net::FTPPermError, "550") }
        it { expect{ @ftp_liar.rename("/foo", "../../bar") }.to raise_error(Net::FTPPermError, "550") }
      end
      describe "when renamed directory is no empty" do
        it { expect{ @ftp_liar.rename("/hip", "/fooby") }.to raise_error(Net::FTPPermError, "550") }
      end
      describe "from root folder" do
        %w( directory file ).each do |o|
          eval(%Q{
            describe "rename #{o}" do
              [ %w( /foo /fooby ), %w( /bar barby ), %w( bas basby ), %w( /hip/foo /hip/fooby ), %w( /hip/bar hip/barby ), %w( hip/bas hip/basby ) ].each do |names|
                it { expect( @ftp_liar.rename(o == 'file' ? names[0] + '.' + o : names[0], o == 'file' ? names[1] + '.' + o : names[1]) ).to eq nil }
              end
            end
          })
        end
      end
      describe "from hip folder" do
        before(:all) { @ftp_liar.chdir("hip") }
        after(:all) { @ftp_liar.chdir("..") }
        %w( directory file ).each do |o|
          eval(%Q{
            describe "rename #{o}" do
              [ %w( ../fooby-foo ../fooby-bar ), %w( ../barby-foo /barby-bar ), %w( /basby-foo ../basby-bar ), %w( /hip/fooby-foo fooby-bar ), %w( barby-foo barby-bar ), %w( basby-foo /hip/basby-bar ) ].each do |names|
                it { expect( @ftp_liar.rename(o == 'file' ? names[0] + '.' + o : names[0], o == 'file' ? names[1] + '.' + o : names[1]) ).to eq nil }
              end
            end
          })
        end
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

  describe "size" do
    describe "when is not connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.quit
      end

      it { expect{ @ftp_liar.size("foo") }.to raise_error(Net::FTPPermError, "530 Please login with USER and PASS.") }
    end

    describe "when is connected" do
      before(:all) do
        @ftp_liar = FTPLiar::FTPLiar.new
        @ftp_liar.mkdir("foo")
        FileUtils.touch("/tmp/.ftp_liar/foo.file")
        File.open('/tmp/.ftp_liar/bar.file', 'w') { |file| file.write("\
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla eu volutpat nulla. Fusce eget dictum lacus. Suspendisse feugiat hendrerit facilisis. Nullam cursus tristique rutrum. Mauris quis finibus erat, quis scelerisque diam. Nam aliquam varius viverra. Sed luctus eleifend tincidunt. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Donec lacinia nunc turpis, at auctor est ornare quis. Donec ac dapibus enim, ac sollicitudin arcu. Mauris velit libero, venenatis eget tortor ac, commodo sollicitudin dolor. In sagittis rhoncus nibh nec dignissim. Phasellus et malesuada metus. Aliquam et nulla vel libero faucibus consectetur. Phasellus interdum et quam sed lacinia.\
          Curabitur auctor dui justo, vitae finibus erat tempor a. Proin feugiat eleifend nisl, sit amet ullamcorper arcu. Etiam eu arcu faucibus, rutrum ligula eget, pellentesque tortor. Donec semper vulputate metus ac scelerisque. Cras cursus enim nec tortor blandit, sit amet accumsan orci porta. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Vivamus vitae neque ac nisi tristique semper eget at nisi. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nulla dignissim mi ut tristique lobortis. Nullam tincidunt hendrerit nunc id aliquet.\
          Cras volutpat tellus lacus, et commodo augue lacinia quis. Praesent ultricies sodales leo, quis posuere magna interdum at. Nunc nec porta mi. Praesent ac tempus dui. Duis facilisis vulputate euismod. Maecenas tortor leo, interdum et leo vel, hendrerit dictum sapien. Nulla at convallis lectus. In vitae aliquam lacus. Aliquam a pharetra odio. Nam quis elit porttitor, ullamcorper ante a, sollicitudin leo.\
          Sed sapien nulla, convallis a purus vitae, hendrerit sagittis nulla. Integer mattis vulputate auctor. Morbi pretium ligula varius massa pellentesque sagittis. Nam tristique rutrum lectus, vel gravida dolor semper non. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Ut amet.\
        ") }
      end
      after(:all) do
        @ftp_liar.rmdir("foo")
        @ftp_liar.delete("foo.file")
        @ftp_liar.delete("bar.file")
      end

      it { expect{ @ftp_liar.size("../../foo.file") }.to raise_error(Net::FTPPermError, "550") }
      it { expect{ @ftp_liar.size("foo") }.to raise_error(Net::FTPPermError, "550") }
      it { expect( @ftp_liar.size("foo.file") ).to be == 0 }
      it { expect( @ftp_liar.size("bar.file") ).to be == 2096 }
    end
  end
end
