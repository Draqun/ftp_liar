require "ftp_liar/version"
require 'fileutils'

module FTPLiar
  class FTPLiar
    # FTP Liar
    # Simple class for test aplication using Net::FTP

    def initialize(*args)
      FileUtils.cd(Dir.tmpdir)
    end

    def getbinaryfile(remotefile, localfile = nil, blocksize = nil)
      # A simple method that manages to copy a remote file to local
      FileUtils.cp(remotefile, localfile ? localfile : File.basename(remotefile))
    end

    def putbinaryfile(localfile, remotefile = nil, blocksize = nil)
      # A simple method that manages to copy a local file on the FTP.
      FileUtils.cp(localfile, remotefile ? remotefile : File.basename(localfile))
    end

    def chdir(path)
      # Method to change directory
      FileUtils.cd(path)
    end

    def nlst(path = '.')
      # A simple method to list data in directory, return list with filename if file
      if File.file?(path)
        [path]
      else
        Dir.entries(path).sort[2..-1]
      end
    end

    def pwd
      # Method return actual directory
      Dir.pwd
    end

    def delete(filename)
      # Method remove file on FTP
      File.delete(filename)
    end

    def rmdir(dirname)
      # Method remove directory on FTP
      Dir.delete(dirname)
    end
  end
end
