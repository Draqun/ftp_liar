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
      @binary = true
      @passive = false
      ObjectSpace.define_finalizer(self, self.method(:finalize))
      if !(user.nil? && passwd.nil?) && (user.nil? || passwd.nil?)
        raise Net::FTPPermError.new("530 User cannot log in.")
      else
        @is_connect = true
      end
      chdir("/")
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
      raise Net::FTPPermError.new("530 Please login with USER and PASS.") unless @is_connect
      if path[0] == "/"
        if path[1..-1].nil?
          path = @ftp_directory
        else
          path = File.join(@ftp_directory, path[1..-1])
        end
      end

      unless absolute_path_indicates_to_ftp_directory?(path) && Dir.exist?(path)
        raise Net::FTPPermError.new("500")
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
      @is_connect = false
      ""
    end

    def closed?()
      # Returns true if the connection is closed.
      !@is_connect
    end

    def connect(host, port = 21)
      # Method imitate connect method in Net::FTP
      @is_connect = true
      nil
    end

    def delete(filename)
      # Method remove file on FTP
      raise Net::FTPPermError.new("530 Please login with USER and PASS.") unless @is_connect
      if filename[0] == "/"
        filename = File.join(@ftp_directory, filename[1..-1])
      else
        filename = File.join(@ftp_directory, filename)
      end
      unless absolute_path_indicates_to_ftp_directory?(filename) && File.exist?(filename)
        raise Net::FTPPermError.new("550")
      end
      File.delete(filename)
      nil
    end

    # :nocov:
    def dir(*args)
      # Alias for list
      list(*args)
    end
    # :nocov:

    def get(remotefile, localfile = File.basename(remotefile), blocksize = nil)
      # A simple method that manages to copy a remote file to local
      raise Net::FTPPermError("530 Please login with USER and PASS.") unless @is_connect

      unless absolute_path_indicates_to_ftp_directory?(remotefile) && File.exist?(remotefile)
        raise Net::FTPPermError.new("550")
      end

      localdir = localfile.split("/")[0...-1].join("/")
      if File.directory?(localfile)
        raise Errno::EISDIR
      end
      unless Dir.exist?(localdir)
        raise Errno::ENOENT
      end
      copy_file(remotefile, localfile)
      nil
    end

    # :nocov:
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
    # :nocov:

    def login(user = "anonymous", passwd = nil, acct = nil)
      # Method imitate login to ftp. When login is "anonymous" it "connect" without password
      if user != "anonymous" && (user.nil? || passwd.nil?)
        raise Net::FTPPermError.new("530 User cannot log in.")
      end
      @is_connect = true
    end

    # :nocov:
    def ls(*args)
      # Alias for list
      list(*args)
    end

    def mdtm(filename)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end
    # :nocov:

    def mkdir(dirname)
      # Creates a remote directory.
      raise Net::FTPPermError.new("530 Please login with USER and PASS.") unless @is_connect
      if dirname.split("/").include?("..") || dirname.include?("/")
        raise Net::FTPPermError.new("550")
      end
      Dir.mkdir( File.join(pwd, dirname) )
      dirname
    rescue Errno::ENOENT
      raise Net::FTPPermError.new("550")
    end

    def mtime(filename, local = false)
      raise NotImplementedError("Method not implemented. Override it if you want use this method.")
    end

    def nlst(path = '.')
      # A simple method to list data in directory, return list with filename if file
      raise Exception("530 Please login with USER and PASS.") unless @is_connect
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
      raise Exception("530 Please login with USER and PASS.") unless @is_connect
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
      raise Exception("530 Please login with USER and PASS.") unless @is_connect
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
      raise Exception("530 Please login with USER and PASS.") unless @is_connect
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

    private
    attr_accessor :ftp_directory
    attr_accessor :is_connection

    def copy_file(from, to)
      FileUtils.copy_file(from, to)
    end

    def absolute_path_indicates_to_ftp_directory?(path)
      File.absolute_path(path).start_with?(@ftp_directory)
    end

    class << self
      def open(host, *args)
        FTPLiar.new(host, *args)
      end
    end
  end
end
