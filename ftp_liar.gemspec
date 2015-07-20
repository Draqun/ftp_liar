# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ftp_liar/version'

Gem::Specification.new do |spec|
  spec.name          = "ftp_liar"
  spec.version       = FtpLiar::VERSION
  spec.authors       = ["Damian Giebas"]
  spec.email         = ["damian.giebas@gmail.com"]
  spec.date          = '2015-07-20'

  spec.summary       = "Simple class for test application using Net::FTP object"
  spec.description   = "Simple class for test application using Net::FTP object"
  spec.homepage      = 'https://github.com/Draqun/ftp_liar'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
