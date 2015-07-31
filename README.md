# FTPLiar

This is experimental gem to simulate Net::FTP object using temporary directory. You use it or your own risk.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ftp_liar'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ftp_liar

## Usage
Use FTPLiar class with proxy pattern, override interesting class.

```ruby
class MyFTP
  def initialize(*args)
    @ftp_liar = FTPLiar::FTPLiar.new(*args)
  end

  def method_missing(name, *args)
    @ftp_liar.send(name, *args)
  end
end
```

If some method raise NotImplementedError override create your own method like in the example
```ruby
class MyFTP
  def initialize(*args)
    @ftp_liar = FTPLiar::FTPLiar.new(*args)
  end

  def mdtm(filename)
    # Do here what do you want.
  end

  def method_missing(name, *args)
    @ftp_liar.send(name, *args)
  end
end
```
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Draqun/ftp_liar.
