require "ftp_liar/version"
require_relative 'ftp_liar_net'
require 'fileutils'
require 'tmpdir'
require 'faker'

module FTPLiar
  class FTPLiar
    # FTP Liar
    # Simple class for test aplication using Net::FTP
    attr_writer :open_timeout, :read_timeout, :debug_mode, :passive
    attr_accessor :binary

    def initialize(host = nil, user = nil, passwd = nil, acct = nil)
      @ftp_directory = File.join(Dir.tmpdir, '.ftp_liar')
      FileUtils.mkdir_p(@ftp_directory)
      FileUtils.cd(@ftp_directory)
      @binary = true
      @passive = false
      ObjectSpace.define_finalizer(self, self.method(:finalize))
      if !(user.nil? && passwd.nil?) && (user.nil? || passwd.nil?)
        raise Net::FTPPermError.new("530 User cannot log in.")
      else
        @is_connection = true
      end
    end

    def finalize(object_id)
      # Finalizer to delete ftp_liar directory
      FileUtils.rm_rf(@ftp_directory)
    end

    # :nocov:
    def abort()
      # Aborts the previous command (ABOR command).
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def acct(account)
      # Sends the ACCT command.
      #
      # This is a less common FTP command, to send account information if the destination host requires it.
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end
    # :nocov:

    def chdir(path)
      # Changes the (remote) directory.
      raise Net::FTPPermError.new("530 Please login with USER and PASS.") unless @is_connection
      if path[0] == "/"
        path = File.join(@ftp_directory, path[1..-1])
      end
      begin
        FileUtils.cd(path)
      rescue
        raise Net::FTPPermError.new("500")
      end
      nil
    end

    def close()
      # Closes the connection. Further operations are impossible until you open a new connection with connect.
      @is_connection = false
      ""
    end

    def closed?()
      # Returns true if the connection is closed.
      !@is_connection
    end

    def connect(host, port = 21)
      # Method immitate connect method in Net::FTP
      nil
    end

    def delete(filename)
      # Method remove file on FTP
      raise Net::FTPPermError.new("530 Please login with USER and PASS.") unless @is_connection
      if filename[0] == "/"
        filename = File.join(@ftp_directory, filename[1..-1])
      else
        filename = File.join(@ftp_directory, filename)
      end
      unless File.exist?(filename) || File.absolute_path(filename).start_with?(@ftp_directory)
        raise Net::FTPPermError.new("550")
      end
      File.delete(filename)
    end

    def dir(*args)
      # Alias for list
      list(*args)
    end

    def get(remotefile, localfile = nil, blocksize = nil)
      # A simple method that manages to copy a remote file to local
      raise Exception("530 Please login with USER and PASS.") unless @is_connection
      FileUtils.cp(remotefile, localfile ? localfile : File.basename(remotefile))
    end

    def getbinaryfile(*args)
      # A simple method that manages to copy a remote file to local
      get(*args)
    end

    def getdir()
      pwd
    end

    def gettextfile(*args)
      get(*args)
    end

    def help(arg = nil)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def list(*args)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def login(*args)
      @is_connection = true
    end

    def ls(*args)
      # Alias for list
      list(*args)
    end

    def mdtm(filename)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def mkdir(dirname)
      new_dirname = escape_name(dirname)
      Dir.mkdir(new_dirname)
    end

    def mtime(filename, local = false)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def nlst(path = '.')
      # A simple method to list data in directory, return list with filename if file
      raise Exception("530 Please login with USER and PASS.") unless @is_connection
      if File.file?(path)
        [path]
      else
        Dir.entries(path).sort[2..-1]
      end
    end

    def noop()
      # Does nothing
      nil
    end

    def put(localfile, remotefile = nil, blocksize = nil)
      # A simple method that manages to copy a local file on the FTP.
      raise Exception("530 Please login with USER and PASS.") unless @is_connection
      FileUtils.cp(localfile, remotefile ? remotefile : File.basename(localfile))
    end

    def putbinaryfile(*args)
      # A simple method that manages to copy a local file on the FTP.
      put(*args)
    end

    def puttextfile(*args)
      put(*args)
    end

    def pwd
      # Method return actual directory
      raise Exception("530 Please login with USER and PASS.") unless @is_connection
      Dir.pwd
    end

    def quit
    end

    def rename(fromname, toname)
      FileUtils.mv(fromname, toname)
    end

    def retrbinary(cmd, blocksize, rest_offset = nil)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def retrlines(cmd)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def rmdir(dirname)
      # Method remove directory on FTP
      raise Exception("530 Please login with USER and PASS.") unless @is_connection
      Dir.delete(dirname)
    end

    def sendcmd(cmd)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def set_socket(sock, get_greeting=true)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def site(arg)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def size(filename)
      File.size(filename)
    end

    def status()
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def storbinary(cmd, file, blocksize, rest_offset = nil)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def sotrlines(cmd, file)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def system()
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def voidcmd(cmd)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    class << self
      def open(host, *args)
        FTPLiar.new(host, *args)
      end
    end

    private
    attr_accessor :ftp_directory
    attr_accessor :is_connection

    def escape_name(filename)
      (dirname.split("/") - [".."]).join
    end
  end
end
