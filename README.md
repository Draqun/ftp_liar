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
    @ftp_liar = FTPLiar::FTPLiar.new
  end

  def method_missing(name, *args)
    @ftp_liar.send(name, *args)
  end
end
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Draqun/ftp_liar.
