# Utilities surrounding the appropriate paths associated with a platform
# This includes both reporting the correct path and divining the platform
# tag associated with a variety of paths
#
# rubocop:disable Metrics/ModuleLength
module Pkg::Paths
  include Pkg::Platforms

  module_function

  # Given a path to an artifact, divine the appropriate platform tag associated
  # with the artifact and path
  def tag_from_artifact_path(path)
    Pkg::Platforms.platform_tags.each do |tag|
      platform, version, arch = Pkg::Platforms.parse_platform_tag(tag)
      if path.include?(platform)
        if path =~ /#{platform}(\/|-)?#{version}/
          if path.include?(arch)
            return tag
          elsif path.include?('noarch')
            # Default to 64bit for no reason in particular
            return "#{platform}-#{version}-x86_64"
          end
        elsif platform == 'windows' || platform == 'cumulus' || platform == 'huaweios'
          if path.include?(arch)
            return tag
          end
        end
      elsif Pkg::Platforms.codename_for_platform_version(platform, version) && path.include?(Pkg::Platforms.codename_for_platform_version(platform, version))
        if path.include?(arch)
          return tag
        elsif path.include?('all')
          # Default to 64bit for no reason in particular
          return "#{platform}-#{version}-amd64"
        end
      end
    end
    raise "I couldn't figure out which platform tag corresponds to #{path}. Teach me?"
  end

  def artifacts_path(platform_tag, package_url = nil, path_prefix = 'artifacts')
    platform, version, architecture = Pkg::Platforms.parse_platform_tag(platform_tag)
    package_format = Pkg::Platforms.package_format_for_tag(platform_tag)

    case package_format
    when 'rpm'
      File.join(path_prefix, Pkg::Config.repo_name, platform, version, architecture)
    when 'swix'
      File.join(path_prefix, platform, Pkg::Config.repo_name, version, architecture)
    when 'deb'
      File.join(path_prefix, 'deb', Pkg::Platforms.get_attribute(platform_tag, :codename), Pkg::Config.repo_name)
    when 'svr4', 'ips'
      File.join(path_prefix, 'solaris', Pkg::Config.repo_name, version)
    when 'dmg'
      File.join(path_prefix, 'mac', Pkg::Config.repo_name, version, architecture)
    when 'msi'
      File.join(path_prefix, 'windows', Pkg::Config.repo_name)
    else
      raise "Not sure where to find packages with a package format of '#{package_format}'"
    end
  end

  def repo_path(platform_tag)
    platform, version, arch = Pkg::Platforms.parse_platform_tag(platform_tag)
    package_format = Pkg::Platforms.package_format_for_tag(platform_tag)

    case package_format
    when 'rpm', 'swix'
      File.join('repos', Pkg::Config.repo_name, platform, version, arch)
    when 'deb'
      File.join('repos', 'apt', Pkg::Platforms.get_attribute(platform_tag, :codename), 'pool', Pkg::Config.repo_name)
    when 'svr4', 'ips'
      File.join('repos', 'solaris', Pkg::Config.repo_name, version)
    when 'dmg'
      File.join('repos', 'mac', Pkg::Config.repo_name, version, arch)
    when 'msi'
      File.join('repos', 'windows', Pkg::Config.repo_name)
    else
      raise "Not sure what to do with a package format of '#{package_format}'"
    end
  end

  def repo_config_path(platform_tag)
    package_format = Pkg::Platforms.package_format_for_tag(platform_tag)

    case package_format
    when 'rpm'
      # rpm/pl-puppet-agent-1.2.5-el-5-i386.repo for example
      File.join('repo_configs', 'rpm', "*#{platform_tag}*.repo")
    when 'deb'
      # deb/pl-puppet-agent-1.2.5-jessie.list
      File.join('repo_configs', 'deb', "*#{Pkg::Platforms.get_attribute(platform_tag, :codename)}*.list")
    when 'msi', 'swix', 'dmg', 'svr4', 'ips'
      nil
    else
      raise "Not sure what to do with a package format of '#{package_format}'"
    end
  end
end
