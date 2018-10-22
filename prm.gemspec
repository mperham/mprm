require 'date'
require_relative './lib/prm/version'
Gem::Specification.new do |s|
  s.name        = 'prm'
  s.version     = PRM::VERSION
  s.summary     = "Package Repository Manager"
  s.description = %Q(PRM (Package Repository Manager) is an Operating System independent Package Repository tool. It allows you to quickly build Debian and Yum Package Repositories. PRM can sync local repositories to S3 compatible object storage systems.)
  s.authors     = ["Brett Gailey", "Mike Perham"]
  s.email       = 'mperham@gmail.com'
  s.files       = Dir.glob("{lib,templates}/**/*")
  s.bindir	  = 'bin'
  s.executables = ['prm']

  s.add_dependency 'parallel', '>= 1.12'
  s.add_dependency 'clamp', '>= 1.0.1'
  s.add_dependency 'arr-pm', '>= 0.0.10'

  s.homepage    = 'https://github.com/mperham/prm'
  s.license = 'MIT'
end
