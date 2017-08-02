# Perform a build exclusively from a build params file. Requires that the build
# params file include a setting for task, which is an array of the arguments
# given to rake originally, including, first, the task name. The params file is
# always loaded when passed, so these variables are accessible immediately.
namespace :pl do
  desc "Build from a build params file"
  task :build_from_params do
    Pkg::Util.check_var('PARAMS_FILE', ENV['PARAMS_FILE'])
    Pkg::Util::Version.git_co(Pkg::Config.ref)
    Rake::Task[Pkg::Config.task[:task]].invoke(Pkg::Config.task[:args])
  end
  desc ""
  task :local_build => "pl:fetch" do
    # If we have a dirty source, bail, because changes won't get reflected in
    # the package builds
    Pkg::Util::Version.fail_on_dirty_source

    Pkg::Util::RakeUtils.invoke_task("package:tar")
    # at this point we're in a directory like puppetserver/target/staging
    # and we want the output to be under puppetserver
    base_output = '../../output'
    # we've got two chdirs before we actually build the packages, set up
    # this variable so we can copy things more easily
    nested_output = '../../../../output'
    FileUtils.mkdir(base_output) unless File.directory?(base_output)
    Dir.chdir('pkg') do
      `tar xf #{Dir.glob("*.gz").join('')}`
      Dir.chdir("#{Pkg::Config.project}-#{Pkg::Config.version}") do
        Pkg::Config.final_mocks.split(" ").each do |mock|
          FileUtils.mkdir("#{nested_output}/#{mock}") unless File.directory?("#{nested_output}/#{mock}")
          `bash controller.sh #{mock}`
          FileUtils.mv(Dir.glob("*.rpm"), "#{nested_output}/#{mock}")
        end
        Pkg::Config.cows.split(" ").each do |cow|
          FileUtils.mkdir("#{nested_output}/#{cow}") unless File.directory?("#{nested_output}/#{cow}")
          `bash controller.sh #{cow}`
          FileUtils.mv(Dir.glob("*.deb"), "#{nested_output}/#{cow}")
        end
      end
    end
  end
end
