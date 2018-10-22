require_relative './helper'
require 'fileutils'

class RepoTest < Minitest::Test
  include FileUtils

  def test_deb
    type = "deb"
    begin
      r, reporoot, srcroot = repo_for(type)
      r.create

      [
        "#{reporoot}/dists/all/Release",
        "#{reporoot}/dists/all/Release.gpg",
        "#{reporoot}/dists/all/main/binary-amd64/faktory-pro_0.9.0-2_amd64.deb",
      ].each do |filename|
        assert File.exist?(filename), "Didn't find expected file `#{filename}` in #{reporoot}"
      end
    ensure
      rm_rf srcroot
      rm_rf reporoot
    end
  end

  def test_rpm
    type = "rpm"
    begin
      r, reporoot, srcroot = repo_for(type)
      r.create

      [
        "#{reporoot}/all/x86_64/repodata/repomd.xml",
        "#{reporoot}/all/x86_64/repodata/repomd.xml.asc",
        "#{reporoot}/all/x86_64/faktory-pro-0.9.0-2.x86_64.rpm",
      ].each do |filename|
        assert File.exist?(filename), "Didn't find expected file `#{filename}` in #{reporoot}"
      end
    ensure
      rm_rf srcroot
      rm_rf reporoot
    end
  end

  def repo_for(type)
    srcroot = "/tmp/#{type}source_#{$$}"
    mkdir_p srcroot
    cp Dir.glob("./test/binaries/fak*"), srcroot

    reporoot = "/tmp/#{type}test_#{$$}"
    mkdir_p reporoot

    r = PRM::Repo.new
    r.release = "all"
    r.arch = (type == "deb" ? "amd64" : "x86_64")
    r.type = type
    r.path = reporoot
    r.component = "main" if type == "deb"
    r.directory = srcroot
    r.origin = "Contributed Systems"
    r.label = "Faktory commercial repo"
    r.gpg = ENV['PRM_USER_KEY']
    r.gpg_sign_algorithm = "sha256"

    [r, reporoot, srcroot]
  end
end
