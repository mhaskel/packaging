# RPM methods used by various libraries and rake tasks

module Pkg::Rpm
  require 'packaging/rpm/repo'

  def prep_rpm_build_dir
    temp = Pkg::Util::File.mktemp
    tarball = "#{Pkg::Config.project}-#{Pkg::Config.version}.tar.gz"
    FileUtils.mkdir_p([temp, "#{temp}/SOURCES", "#{temp}/SPECS"])
    Pkg::Util::File::cp_pr FileList["pkg/#{tarball}*"], "#{temp}/SOURCES"
    # If the file ext/redhat/<project>.spec exists in the tarball, we use it. If
    # it doesn't we try to 'erb' the file from a predicted template in source,
    # ext/redhat/<project>.spec.erb. If that doesn't exist, we fail. To do this,
    # we have to open the tarball.
    Pkg::Util::File::cp_p("pkg/#{tarball}", temp)

    # Test for specfile in tarball
    %x(tar -tzf #{File.join(temp, tarball)}).split.grep(/\/ext\/redhat\/#{Pkg::Config.project}.spec$/)

    if $?.success?
      sh "tar -C #{temp} -xzf #{File.join(temp, tarball)} #{Pkg::Config.project}-#{Pkg::Config.version}/ext/redhat/#{Pkg::Config.project}.spec"
      cp("#{temp}/#{Pkg::Config.project}-#{Pkg::Config.version}/ext/redhat/#{Pkg::Config.project}.spec", "#{temp}/SPECS/")
    elsif File.exists?("ext/redhat/#{Pkg::Config.project}.spec.erb")
      Pkg::Util::File.erb_file("ext/redhat/#{Pkg::Config.project}.spec.erb", "#{temp}/SPECS/#{Pkg::Config.project}.spec", nil, :binding => Pkg::Config.get_binding)
    else
      fail "Could not locate redhat spec ext/redhat/#{Pkg::Config.project}.spec or ext/redhat/#{Pkg::Config.project}.spec.erb"
    end
    temp
  end
end
