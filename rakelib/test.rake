require 'awesome_print'
require 'pp'

namespace :test do
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

  def projects(from, to)
    require 'soap/projects'
    client = SOAP::Projects.new(from, to)
    if client.status == 'S'
      yield client.data
    else
      puts "Error: #{client.message}" 
    end
  end

  desc 'AQUa projects test'
  task :aqua_projects do
    puts 'Getting project data from AQUA'
    from = to = '02.10.2014'
    projects(from, to) do |data|
      data.each do |row|
        ap row.map { |v| v[1] }.join("\t")
      end
    end
  end

  desc 'AQUa projects list'
  task :aqua_projects_list do
    puts 'Getting project data from AQUA'
    from, to = '01.01.2000', '01.01.2050'
    open('projects.tsv', 'w') do |f|
      projects(from, to) do |data|
        data.each do |row|
          f.puts row.map { |v| v[1] }.join("\t")
        end
      end
    end
    puts 'Done!'
  end
end
