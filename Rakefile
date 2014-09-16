desc 'Specs'
task default: :test

desc 'Specs'
task :test do
  sh 'rspec spec'
end

namespace :db do
  desc 'Database setup (schema deployment and data seed)'
  task setup: [:schema, :seed]

  desc 'Database schema deployment'
  task :schema do
    require './db/schema'
    puts 'Schema setup'
    Schema.new('db/schema.yml').deploy
  end

  desc 'Seed data to the database'
  task :seed do
    puts 'Data seed'
  end
end

desc 'Intergation iteration'
task :integration do
  require './models/user'
  puts "Users in db: #{User.count}"
end
