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
end

namespace :test do
  require 'awesome_print'
  require 'pp'

  desc 'Aqua lot test'
  task :aqua_lot do
    require 'models/aqua_lot'
    lot = AquaLot.new(343163,819607)
    ap lot.to_h
  end

  desc 'Contractors list test'
  task :contractors_list do
    require 'models/aqua_lot'
    require 'models/contractors_list_builder'
    lot = AquaLot.new(343163,819607)
    builder = ContractorsListBuilder.new(lot)
    ap builder.contractors
  end

  desc 'SOAP client test (projects)'
  task :soap_projects do
    require 'soap/projects'
    puts 'Getting project data from AQUA'
    from = '13.10.2014'
    to = '13.10.2014'
    client = SOAP::Projects.new(from, to)
    return puts "Error: #{client.message}" unless client.status == 'S'
    # open('projects.tsv', 'w') do |f|
      client.data.each do |row|
      #   # f.puts template % row
         ap row.map { |v| v[1] }.join("\t")
      end
    # end
  end
end
