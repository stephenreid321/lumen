task :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'boot.rb'))
end

namespace :jobs do
  
  desc 'Clear the delayed_job queue'
  task :clear => :environment do
    Delayed::Job.delete_all
  end

  desc 'Start a delayed_job worker'
  task :work => :environment do
    Delayed::Worker.new.start
  end
  
  desc 'Start a delayed_job worker and exit when all available jobs are complete'
  task :workoff => :environment do
    Delayed::Worker.new(:exit_on_complete => true).start
  end  
  
end