require 'bundler/gem_tasks'
require 'rake/testtask'

task :clean do
  %w[
    coverage
    gem_graph.png
  ].each do |path|
    rm_rf path, verbose: false
  end
end

task :coverage do
  ENV['COVERAGE'] = '1'
  Rake::Task['test'].execute
end

Rake::TestTask.new(:test) do |t|
  ENV['TESTOPTS'] = ENV['TESTOPTS'] || '--verbose'
  t.libs << 'lib'
  t.test_files = FileList['test/fixed_width_file_validator_test.rb']
end

task default: :test
