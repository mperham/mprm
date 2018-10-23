require 'fileutils'
require 'zlib'
require 'erb'
require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'
require 'parallel'
require 'time'
require 'thread'

module Debian
  def build_apt_repo(path, component, arch, release, label, origin, gpg, nocache)
    release.each { |r|
      component.each { |c|
        arch.each { |a|
          fpath = path + "/dists/" + r + "/" + c + "/" + "binary-" + a + "/"
          pfpath = fpath + "Packages"
          rfpath = fpath + "Release"

          MPRM.logger.debug "Building Path: #{fpath}"

          FileUtils.mkpath(fpath)
          FileUtils.touch(pfpath)
          FileUtils.touch(rfpath)
          generate_packages_gz(fpath,pfpath,path,rfpath,r,c,a)
        }
      }
      generate_release(path,r,component,arch,label,origin)

      unless gpg == false
        generate_release_gpg(path,r, gpg)
      end
    }
  end

  def move_apt_packages(path,component,arch,release,directory)
    unless File.exist?(directory)
      MPRM.logger.debug "ERROR: #{directory} doesn't exist... not doing anything\n"
      return false
    end

    files_moved = []
    release.each { |r|
      component.each { |c|
        arch.each { |a|
          Dir.glob(directory + "/*.deb") do |file|
            MPRM.logger.debug file
            if file =~ /^.*#{a}.*\.deb$/i || file =~ /^.*all.*\.deb$/i || file =~ /^.*any.*\.deb$/i
              if file =~ /^.*#{r}.*\.deb$/i
                # Lets do this here to help mitigate packages like "asdf-123+wheezy.deb"
                FileUtils.cp(file, "#{path}/dists/#{r}/#{c}/binary-#{a}/")
                FileUtils.rm(file)
              else
                FileUtils.cp(file, "#{path}/dists/#{r}/#{c}/binary-#{a}/")
                files_moved << file
              end
            end
          end
        }
      }
    }

    files_moved.each do |f|
      if File.exist?(f)
        FileUtils.rm(f)
      end
    end
    # Regex?
    #/^.*#{arch}.*\.deb$/i
  end

  def generate_packages_gz(fpath,pfpath,path,rfpath,r,c,a)
    MPRM.logger.debug "Generating Packages: #{r} : #{c} : binary-#{a}"

    npath = "dists/" + r + "/" + c + "/" + "binary-" + a + "/"

    d = File.open(pfpath, "w+")
    write_mutex = Mutex.new

    Parallel.each(Dir.glob("#{fpath}*.deb"), in_threads: 5) do |deb|
      algs = {
        'md5' => Digest::MD5.new,
        'sha1' => Digest::SHA1.new,
        'sha256' => Digest::SHA256.new
      }
      sums = {
        'md5' => '',
        'sha1' => '',
        'sha256' => ''
      }
      tdeb = File.basename(deb)
      init_size = File.size(deb)
      deb_contents = nil

      FileUtils.mkdir_p "tmp/#{tdeb}/"
      if not nocache
        sums.keys.each do |s|
          sum_path = "#{path}/dists/#{r}/#{c}/binary-#{a}/#{s}-results/#{tdeb}"
          FileUtils.mkdir_p File.dirname(sum_path)

          if File.exist?(sum_path)
            stored_sum = File.read(sum_path)
            sum = stored_sum unless nocache.nil?
          end

          unless sum
            deb_contents ||= File.read(deb)
            sum = algs[s].hexdigest(deb_contents)
          end

          sums[s] = sum
          if nocache.nil?
            File.open(sum_path, 'w') { |f| f.write(sum) }
          elsif sum != stored_sum
            MPRM.logger.debug "WARN: #{s}sum mismatch on #{deb}\n"
          end
        end
      end
      `ar p #{deb} control.tar.gz | tar zx -C tmp/#{tdeb}/`

      package_info = [
        "Filename: #{npath}#{s3_compatible_encode(tdeb)}",
        "MD5: #{sums['md5']}",
        "SHA1: #{sums['sha1']}",
        "SHA256: #{sums['sha256']}",
        "Size: #{init_size}"
      ]

      write_mutex.synchronize do
        # Copy the control file data into the Packages list
        d.write(File.read("tmp/#{tdeb}/control").gsub!(/\n+/, "\n"))
        d.write(package_info.join("\n"))
        d.write("\n\n") # blank line between package info in the Packages file
      end
    end

    FileUtils.rmtree 'tmp/'

    d.close

    Zlib::GzipWriter.open(pfpath + ".gz") do |gz|
      f = File.new(pfpath, "r")
      f.each do |line|
        gz.write(line)
      end
    end
  end

  def generate_release(path,release,component,arch,label,origin)
    date = Time.now.utc

    release_info = {}
    unreasonable_array = ["Packages", "Packages.gz", "Release"]
    component_ar = []
    Dir.glob(path + "/dists/" + release + "/*").select { |f|
      f.slice!(path + "/dists/" + release + "/")
      unless f == "Release" or f == "Release.gpg"
        component_ar << f
      end
    }

    component_ar.each do |c|
      arch.each do |ar|
        unreasonable_array.each do |unr|
          tmp_path = "#{path}/dists/#{release}/#{c}/binary-#{ar}"
          tmp_hash = {}
          filename = "#{c}/binary-#{ar}/#{unr}".chomp

          byte_size = File.size("#{tmp_path}/#{unr}").to_s
          file_contents = File.read("#{tmp_path}/#{unr}")

          tmp_hash['size'] = byte_size
          tmp_hash['md5'] = Digest::MD5.hexdigest(file_contents)
          tmp_hash['sha1'] = Digest::SHA1.hexdigest(file_contents)
          tmp_hash['sha256'] = Digest::SHA256.hexdigest(file_contents)
          release_info[filename] = tmp_hash
        end
      end
    end


    template_dir = File.join(File.dirname(__FILE__), "..", "..", "templates")
    erb = ERB.new(File.read("#{template_dir}/deb_release.erb"), nil, "-").result(binding)

    File.open("#{path}/dists/#{release}/Release.tmp","wb") do |x|
      x.puts erb
    end

    FileUtils.move("#{path}/dists/#{release}/Release.tmp", "#{path}/dists/#{release}/Release")
  end

  # We expect that GPG is installed and a key has already been made
  def generate_release_gpg(path,release,gpg)
    Dir.chdir("#{path}/dists/#{release}") do
      if gpg_sign_algorithm.nil?
        sign_algorithm = "none"
      else
        sign_algorithm = gpg_sign_algorithm
      end

      if gpg.nil?
        sign_cmd = "gpg --digest-algo \"#{sign_algorithm}\" --yes --output Release.gpg -b Release"
      elsif !gpg_passphrase.nil?
        sign_cmd = "echo \'#{gpg_passphrase}\' | gpg --digest-algo \"#{sign_algorithm}\" -u #{gpg} --passphrase-fd 0 --yes --output Release.gpg -b Release"
      else
        sign_cmd = "gpg --digest-algo \"#{sign_algorithm}\" -u #{gpg} --yes --output Release.gpg -b Release"
      end
      MPRM.logger.debug "Exec: #{sign_cmd}"
      MPRM.logger.debug `#{sign_cmd}`
    end
  end

  def s3_compatible_encode(str)
    str.gsub(/[#\$&'\(\)\*\+,\/:;=\?@\[\]]/) { |x| x.each_byte.map { |b| '%' + b.to_s(16) }.join }
  end
end


