require 'rake/testtask'

test_tasks = Dir['test/*'].map { |f| (m = f.match(/test\/(\w+)_test.rb/)) ? m[1] : nil }.compact

test_tasks.each do |t|
  Rake::TestTask.new("test:#{t}") do |test|
    test.pattern = "test/#{t}_test.rb"
    test.verbose = true
  end
end

desc "Run application test suite"
task :test => test_tasks.map { |t| "test:#{t}" }
