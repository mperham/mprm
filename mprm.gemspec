require_relative './lib/mprm/version'

Gem::Specification.new do |s|
  s.name        = 'mprm'
  s.version     = PRM::VERSION
  s.summary     = "Mike's Package Repository Manager"
  s.description = %Q(Mike's PRM (Package Repository Manager) is an OS-independent Package Repository tool. It allows you to quickly build Debian and Yum Package Repositories.)
  s.authors     = ["Brett Gailey", "Mike Perham"]
  s.email       = 'mperham@gmail.com'
  s.files       = Dir.glob("{lib,templates}/**/*")
  s.bindir	  = 'bin'
  s.executables = ['mprm']

  s.add_dependency 'parallel', '>= 1.12'
  s.add_dependency 'arr-pm', '>= 0.0.10'
  s.add_dependency 'clamp', '>= 1.0.1'

  s.homepage    = 'https://github.com/mperham/prm'
  s.license = 'MIT'
end
