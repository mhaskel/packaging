# Rake Task to dynamically create a Jenkins job to model the
# pl:jenkins:uber_build set of tasks in a Matrix job where each cell is an
# individual build to be run. This would be nice if we only had to create one job,
# but alas, we're actually creating three jobs.
# 1) a packaging job that builds the packages
#                     |
#                     V
# 2) a repo creation job that creates repos from those packages
#                     |
#                     V
# 3) (optional) a job to proxy the downstream job passed in via DOWNSTREAM_JOB
#

namespace :pl do
  namespace :jenkins do
    desc "Dynamic Jenkins UBER build: Build all the things with ONE job"
    task :uber_build, [:poll_interval] => "pl:fetch" do |t, args|
      args.with_defaults(:poll_interval => 0)
      poll_interval = args.poll_interval.to_i

      # If we have a dirty source, bail, because changes won't get reflected in
      # the package builds
      Pkg::Util::Version.fail_on_dirty_source

      # Use JSON to parse the json part of the submission, so we want to fail
      # here also if JSON isn't available
      Pkg::Util.require_library_or_fail 'json'

      #fail Pkg::Config.print_config
      Pkg::Util::RakeUtils.invoke_task("package:tar")
      `tar xf #{Dir.glob("*.gz").join('')}`
      Dir.chdir('pkg') do
        Dir.chdir("#{Pkg::Config.project}-#{Pkg::Config.version}") do
          Pkg::Config.final_mocks.split(" ").each do |mock|
            if mock =~ /el-7/
              fail "#{Dir.pwd}\n===\n#{Dir.glob('**/*')}\n===\n#{Pkg::Config.print_config}"
            else
              puts "skipping #{mock} for now"
            end
          end
        end
      end
    end

    # Task to trigger the jenkins job we just created. This uses a lot of the
    # same logic in jenkins.rake, with different parameters.
    # TODO make all this replicated code a better, more abstract method
    task :trigger_dynamic_job, :name do |t, args|
      name = args.name

      properties = Pkg::Config.config_to_yaml
      bundle = Pkg::Util::Git.git_bundle('HEAD')

      # Create a string of metrics to send to Jenkins for data analysis
      if Pkg::Config.pe_version
        metrics = "#{ENV['USER']}~#{Pkg::Config.version}~#{Pkg::Config.pe_version}~#{Pkg::Config.team}"
      else
        metrics = "#{ENV['USER']}~#{Pkg::Config.version}~N/A~#{Pkg::Config.team}"
      end

      # Construct the parameters, which is an array of hashes we turn into JSON
      parameters = [{ "name" => "BUILD_PROPERTIES", "file"  => "file0" },
                    { "name" => "PROJECT_BUNDLE",   "file"  => "file1" },
                    { "name" => "PROJECT",          "value" => "#{Pkg::Config.project}" },
                    { "name" => "METRICS",          "value" => "#{metrics}" }]

      # Contruct the json string
      json = JSON.generate("parameter" => parameters)

      # The args array that holds  all of the arguments we pass
      # to the curl utility method.
      curl_args =  [
      "-Fname=BUILD_PROPERTIES", "-Ffile0=@#{properties}",
      "-Fname=PROJECT_BUNDLE",   "-Ffile1=@#{bundle}",
      "-Fname=PROJECT",          "-Fvalue=#{Pkg::Config.project}",
      "-Fname=METRICS",          "-Fvalue=#{metrics}",
      "-FSubmit=Build",
      "-Fjson=#{json.to_json}",
      ]

      # Contstruct the job url
      trigger_url = "#{Pkg::Config.jenkins_build_host}/job/#{name}/build"

      _, retval = Pkg::Util::Net.curl_form_data(trigger_url, curl_args)
      if Pkg::Util::Execution.success?(retval)
        Pkg::Util::Net.print_url_info("http://#{Pkg::Config.jenkins_build_host}/job/#{name}")
        puts "Your packages will be available at http://#{Pkg::Config.builds_server}/#{Pkg::Config.project}/#{Pkg::Config.ref}"
      else
        fail "An error occurred submitting the job to jenkins. Take a look at the preceding http response for more info."
      end

      # Clean up after ourselves
      rm bundle
      rm properties
    end
  end
end

namespace :pe do
  namespace :jenkins do
    desc "Dynamic Jenkins UBER build: Build all the things with ONE job"
    task :uber_build, [:poll_interval] do |t, args|
      Pkg::Util.check_var("PE_VER", Pkg::Config.pe_version)
      args.with_defaults(:poll_interval => 0)
      Rake::Task["pl:jenkins:uber_build"].invoke(args.poll_interval)
    end
  end
end
