lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'iolaus/version'

Gem::Specification.new do |spec|
  spec.name          = 'iolaus'
  spec.version       = Iolaus::VERSION
  spec.authors       = ['Charlie Sharpsteen']
  spec.email         = ['source@sharpsteen.net']

  spec.summary       = 'HTTP request helpers for Typhoeus'
  spec.description   = <<~EOS
    The Iolaus gem provides helpers for managing batches of parallel Typhoeus
    requests. These helpers provide functionality such as rate limiting, retry
    logic, and async processing of result sets.
  EOS
  spec.homepage      = 'https://github.com/Sharpie/ruby-iolaus'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'concurrent-ruby',                '~> 1.0'
  spec.add_runtime_dependency 'typhoeus',                       '~> 1.0'

  spec.add_development_dependency 'bundler',                    '~> 1.17'
  spec.add_development_dependency 'sinatra',                    '~> 2.0'
  spec.add_development_dependency 'rake',                       '~> 10.0'
  spec.add_development_dependency 'rspec',                      '~> 3.8'
  spec.add_development_dependency 'yard',                       '~> 0.9'
end
