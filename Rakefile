$LOAD_PATH << '.'

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
    require 'db/schema'
    puts 'Schema setup'
    Schema.new('db/schema.yml').deploy
  end

  desc 'Seed data to the database'
  task :seed do
    require 'db/seed'
    puts 'Data seed'
    Seed.new('./db/seed.yml').apply
  end
end

namespace :integration do
  desc 'Intergation iteration'
  task :iteration do
    require 'models/user'
    puts "Users in db: #{User.count}"
  end

  desc 'Intergation test'
  task :test do
    require 'soap/client'
    puts 'Getting project data from AQUA'
    template = "%{spp_parent}\t%{spp}\t%{pspnr}\t%{name}\t%{long_name}\t" \
               "%{long_text}\t%{mark_deleted}\t%{posid}\t%{mark_block_planning}"
    open('projects.tsv', 'w') do |f|
      SOAP::Client.new.data.each do |row|
        f.puts template % row
      end
    end
  end
end
