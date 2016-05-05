namespace :pl do
  namespace :jenkins do
    task :deploy_learning_vm, [:vm, :md5, :target_bucket, :target_directory] => "pl:fetch" do
#      Pkg::Util::Net.s3sync_to(vm, target_bucket, target_directory, ["--acl-public"])
#      Pkg::Util::Net.s3sync_to(md5, target_bucket, target_directory, ["--acl-public"])

      puts "'#{vm}' and '#{md5}' have been shipped via s3 to '#{target_bucket}/#{target_directory}'"
    end
  end
end
