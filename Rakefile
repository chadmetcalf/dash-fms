desc "run your job directly for testing"
task :run_job do |task, args|
  print "\n Name of Job to force run: "
  job_name = STDIN.gets.chomp

  require 'dotenv'
  Dotenv.load

  require 'dashing'
  require 'dashing/cli'
  require 'dashing/downloader'
  puts "Running #{job_name}"
  Dashing::CLI.start(['job', job_name])
  puts "Finished #{job_name}"
end
