# Utility methods for handling files and directories
require 'fileutils'

module Pkg::Util::File

  class << self
    def mktemp
      mktemp = Pkg::Util::Tool.find_tool('mktemp', :required => true)
      Pkg::Util::Execution.ex("#{mktemp} -d -t pkgXXXXXX").strip
    end

    def empty_dir?(dir)
      File.exist?(dir) and File.directory?(dir) and Dir["#{dir}/**/*"].empty?
    end

    # Returns an array of all the directories at the top level of #{dir}
    #
    def directories(dir)
      if File.directory?(dir)
        Dir.chdir(dir) do
          Dir.glob("*").select { |entry| File.directory?(entry) }
        end
      end
    end

    def cp_p(src, dest, options = {})
      mandatory = { :preserve => true }
      FileUtils.cp(src, dest, options.merge(mandatory))
    end

    def cp_pr(src, dest, options = {})
      mandatory = { :preserve => true }
      FileUtils.cp_r(src, dest, options.merge(mandatory))
    end

    def file_exists?(file, args = { :required => false })
      exists = File.exist? file
      if !exists and args[:required]
        fail "Required file #{file} could not be found"
      end
      exists
    end

    def file_writable?(file, args = { :required => false })
      writable = File.writable? file
      if !writable and args[:required]
        fail "File #{file} is not writable"
      end
      writable
    end

    alias :get_temp :mktemp

    def erb_string(erbfile, b = binding)
      template = File.read(erbfile)
      message  = ERB.new(template, nil, "-")
      message.result(b)
    end

    def erb_file(erbfile, outfile = nil, remove_orig = false, opts = { :binding => binding })
      outfile ||= File.join(mktemp, File.basename(erbfile).sub(File.extname(erbfile), ""))
      output = erb_string(erbfile, opts[:binding])
      File.open(outfile, 'w') { |f| f.write output }
      puts "Generated: #{outfile}"
      FileUtils.rm_rf erbfile if remove_orig
      outfile
    end

    def untar_into(source, target = nil, options = "")
      tar = Pkg::Util::Tool.find_tool('tar', :required => true)
      # We only accept a writable directory as a target
      if target and !target.empty? and file_writable?(target) and File.directory?(target)
        target_opts = "-C #{target}"
      end
      if file_exists?(source, :required => true)
        Pkg::Util::Execution.ex(%Q(#{tar} #{options} #{target_opts} -xf #{source}))
      end
    end

    def install_files_into_dir(file_patterns, workdir)
      install = []
      # We need to add our list of file patterns from the configuration; this
      # used to be a list of "things to copy recursively", which would install
      # editor backup files and other nasty things.
      #
      # This handles that case correctly, with a deprecation warning, to augment
      # our FileList with the right things to put in place.
      #
      # Eventually, when all our projects are migrated to the new standard, we
      # can drop this in favour of just pushing the patterns directly into the
      # FileList and eliminate many lines of code and comment.
      Dir.chdir(Pkg::Config.project_root) do
        file_patterns.each do |pattern|
          if File.directory?(pattern) and !Pkg::Util::File.empty_dir?(pattern)
            install << Dir[pattern + "/**/*"]
          else
            install << Dir[pattern]
          end
        end
        install.flatten!

        # Transfer all the files and symlinks into the working directory...
        install = install.select { |x| File.file?(x) or File.symlink?(x) or Pkg::Util::File.empty_dir?(x) }

        install.each do |file|
          if Pkg::Util::File.empty_dir?(file)
            FileUtils.mkpath(File.join(workdir, file), :verbose => false)
          else
            FileUtils.mkpath(File.dirname(File.join(workdir, file)), :verbose => false)
            FileUtils.cp(file, File.join(workdir, file), :verbose => false, :preserve => true)
          end
        end
      end
      Pkg::Util::Version.versionbump(workdir) if Pkg::Config.update_version_file
    end
  end
end

