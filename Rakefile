$LOAD_PATH << '.'

desc 'Specs'
task default: :test

desc 'Specs'
task :test do
  sh 'rspec spec'
end

namespace :integration do
  desc 'Intergation iteration'
  task :iteration do
    require 'models/user'
    puts "Users in db: #{User.count}"
  end
end
