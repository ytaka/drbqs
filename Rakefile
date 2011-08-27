require "bundler/gem_tasks"

desc "Run all specs"
task 'spec:all' => ['spec:unit', 'spec:integration']

desc "Run specs of unit test"
task 'spec:unit' do
  filelist = FileList['spec/**/*_spec.rb'].delete_if do |path|
    /integration_test/ =~ path
  end
  filelist.each do |path|
    sh "rspec #{path}"
  end
  Rake::Task['clean:temporary'].execute
end

desc "Run specs of integration test"
task 'spec:integration' do
  FileList['spec/integration_test/**/*_spec.rb'].sort.each do |path|
    sh "rspec #{path}"
  end
  Rake::Task['clean:temporary'].execute
end

task :default => 'spec:all'

require 'yard'
YARD::Rake::YardocTask.new

desc "Remove temporary home directory for specs."
task "clean:temporary" do
  dir = File.join(File.dirname(__FILE__), 'spec', 'home_for_spec')
  if File.exist?(dir)
    FileUtils.rm_r(dir)
  end
end
