require 'rake/testtask'

desc "Run application test suite"
task :test do
  Rake::TestTask.new do |t|
    t.test_files = FileList['test/*_test.rb']
    t.verbose = true
  end
end

task :default => :test