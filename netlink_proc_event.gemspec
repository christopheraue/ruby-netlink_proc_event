# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'netlink_proc_event/version'

Gem::Specification.new do |spec|
  spec.name          = "netlink_proc_event"
  spec.version       = NetlinkProcEvent::VERSION
  spec.authors       = ["Christopher Aue"]
  spec.email         = ["mail@christopheraue.net"]

  spec.summary       = "Netlink bindings to subscribe to process events (exec, fork, etc.)."
  spec.homepage      = "https://github.com/christopheraue/ruby-netlink_proc_events"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency 'ffi', '~> 1.9'
end
