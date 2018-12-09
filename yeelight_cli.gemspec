lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'yeelight_cli/version'
require 'yeelight_cli/bulb'
require 'yeelight_cli/bulb_group'
require 'yeelight_cli/bulb/args_validator'
require 'yeelight_cli/color_processor'
require 'yeelight_cli/tcp_socket_client'

Gem::Specification.new do |spec|
  spec.name          = 'yeelight_cli'
  spec.version       = YeelightCli::VERSION
  spec.authors       = ['snthpr1d3']
  spec.email         = ['github@maletin.work']

  spec.summary       = 'Yeelight CLI client'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'gli'
  spec.add_dependency 'paint'
end
