require 'awesome_print'
require 'pp'

namespace :test do
  desc 'Aqua lot test'
  task :aqua_lot do
    require 'models/aqua_lot'
    lot = AquaLot.new(343163, 819607)
    ap lot.to_h
  end

  desc 'Contractors list test'
  task :contractors_list do
    require 'models/aqua_lot'
    require 'models/contractors_list_builder'
    lot = AquaLot.new(343163, 819607)
    builder = ContractorsListBuilder.new(lot)
    ap builder.contractors
  end

  def projects(from, to)
    require 'aqua/projects_endpoint'
    response = ProjectsEndpoint.query(from, to)
    if response.status == 'S'
      yield response.data
    else
      puts "Error: #{response.message}"
    end
  end

  PROJECTS_TEST_DATE = '02.10.2014'

  desc "AQUa projects test for #{PROJECTS_TEST_DATE}"
  task :aqua_projects do
    puts "Getting project data from AQUA for #{PROJECTS_TEST_DATE}"
    from = to = PROJECTS_TEST_DATE
    projects(from, to) do |data|
      data.each do |row|
        ap row.map { |v| v[1] }.join("\t")
      end
    end
  end

  desc 'Save AQUa projects list to projects.tsv'
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

  desc 'AQUa lots test'
  task :send_aqua_lot do
    require 'models/aqua_lot'
    require 'models/contractors_list_builder'
    require 'aqua/lots_endpoint'
    lot = AquaLot.new(343163, 819607)
    data = lot.to_h
    contractors = ContractorsListBuilder.new(lot).contractors
    data[:uch_ksdazd_tab] = { item: contractors.values }
    response = LotsEndpoint.send(i_lots: { item: data })
    puts "#{response.status} #{response.message}"
  end

  desc 'VCR dump'
  task :vcr_to_xml, [:name] do |t, args|
    require 'yaml'
    cassette = YAML.load_file("fixtures/vcr_cassettes/#{args.name}.yml")
    request =  cassette['http_interactions'][0]['request']['body']['string']
    IO.write("fixtures/vcr_cassettes/#{args.name}.xml", request)
  end
end
