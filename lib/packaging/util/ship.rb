# Module for shipping all packages to places
require 'tmpdir'
module Pkg::Util::Ship
  module_function

  def collect_packages(pkg_exts, excludes = []) # rubocop:disable Metrics/MethodLength
    pkgs = pkg_exts.map { |ext| Dir.glob(ext) }.flatten
    if excludes
      excludes.each do |exclude|
        pkgs.delete_if { |p| p.match(exclude) }
      end
    end
    if pkgs.empty?
      $stdout.puts "No packages with (#{pkg_exts.join(', ')}) extensions found staged in 'pkg'"
      $stdout.puts "Maybe your excludes argument (#{excludes}) is too restrictive?"
    end
    pkgs
  end

  # Takes a set of packages and reorganizes them into the final repo
  # structure before they are shipping out to their final destination.
  #
  # This assumes the working directory is a temporary directory that will
  # later be cleaned up
  def reorganize_packages(pkgs, tmp)
    new_pkgs = []
    pkgs.each do |pkg|
      platform_tag = Pkg::Paths.tag_from_artifact_path(pkg)
      path = Pkg::Paths.artifacts_path(platform_tag, nil, 'pkg')
      FileUtils.mkdir_p File.join(tmp, path)
      FileUtils.cp pkg, File.join(tmp, path)
      new_pkgs << File.join(path, File.basename(pkg))
    end
    new_pkgs
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def ship_pkgs(pkg_exts, staging_server, remote_path, options = { excludes: [], chattr: true })
    # First find the packages to be shipped. We must find them before moving
    # to our temporary staging directory
    local_packages = collect_packages(pkg_exts, options[:excludes])

    tmpdir = Dir.mktmpdir
    staged_pkgs = reorganize_packages(local_packages, tmpdir)

    puts staged_pkgs.sort
    puts "Do you want to ship the above files to (#{staging_server})?"
    if Pkg::Util.ask_yes_or_no
      extra_flags = ['--ignore-existing', '--delay-updates']
      extra_flags << '--dry-run' if ENV['DRYRUN']

      staged_pkgs.each do |pkg|
        Pkg::Util::Execution.retry_on_fail(times: 3) do
          remote_pkg = pkg.gsub('pkg', remote_path)
          remote_basepath = File.dirname(remote_pkg)
          Pkg::Util::Net.remote_ssh_cmd(staging_server, "mkdir -p #{remote_basepath}")
          Pkg::Util::Net.rsync_to(
            File.join(tmpdir, pkg),
            staging_server,
            remote_basepath,
            extra_flags: extra_flags
          )

          Pkg::Util::Net.remote_set_ownership(staging_server, 'root', 'release', [remote_pkg])
          Pkg::Util::Net.remote_set_permissions(staging_server, '0664', [remote_pkg])
          Pkg::Util::Net.remote_set_immutable(staging_server, [remote_pkg]) if options[:chattr]
        end
      end
    end
  end
end