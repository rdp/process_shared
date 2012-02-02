require 'rake/extensiontask'
require 'rake/testtask'
require 'rubygems/package_task'

def gemspec
  @gemspec ||= eval(File.read('process_shared.gemspec'), binding, 'process_shared.gemspec')
end

Rake::ExtensionTask.new('helper') do |ext|
  ext.lib_dir = 'lib/process_shared/posix'
end

desc 'Run the tests'
task :default => [:test]

Rake::TestTask.new(:test => [:compile]) do |t|
  t.pattern = 'spec/process_shared/**/*_spec.rb'
  t.libs.push 'spec'
end

Gem::PackageTask.new(gemspec) do |p|
  p.need_tar = true
  p.gem_spec = gemspec
end

task :gem => :compile
