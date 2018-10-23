require 'mprm/debian'
require 'mprm/rpm'

module MPRM
  class Repo
    include Debian
    include Redhat

    attr_accessor :path
    attr_accessor :type
    attr_accessor :component
    attr_accessor :arch
    attr_accessor :release
    attr_accessor :label
    attr_accessor :origin
    attr_accessor :gpg
    attr_accessor :gpg_passphrase
    attr_accessor :gpg_sign_algorithm
    attr_accessor :directory
    attr_accessor :nocache

    def create
      if "#{@type}" == "deb"
        parch,pcomponent,prelease = _parse_vars(arch,component,release)
        if directory
          build_apt_repo(path,pcomponent,parch,prelease,label,origin,gpg,nocache)
          if move_apt_packages(path,pcomponent,parch,prelease,directory) == false
            return
          end
        end
        build_apt_repo(path,pcomponent,parch,prelease,label,origin,gpg,nocache)
      elsif "#{@type}" == "rpm"
        component = nil
        parch,pcomponent,prelease = _parse_vars(arch,component,release)
        if directory
          build_rpm_repo(path,parch,prelease,gpg)
          if move_rpm_packages(path,parch,prelease,directory) == false
            return
          end
        end
        build_rpm_repo(path,parch,prelease,gpg)
      end
    end

    def _parse_vars(arch_ar,component_ar,release_ar)
      arch_ar = arch.split(",")
      if !component.nil?
        component_ar = component.split(",")
      end
      release_ar = release.split(",")
      [arch_ar,component_ar,release_ar]
    end
  end
end
