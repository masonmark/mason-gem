# Mason 2016-01-23: I got this default started Rakefile from http://guides.rubygems.org/make-your-own-gem/#writing-tests

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test
