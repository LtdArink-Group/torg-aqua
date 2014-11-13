require 'awesome_print'
require 'pp'

GUID = 'A7245F5FA1C3E92F72E60D102021AA47'
PLAN_SPEC_GUID = [GUID].pack('H*')

namespace :test do
  task :guid do
    require 'db/db'
    ap DB.query_value(<<-sql, GUID).class
      select ps.guid
        from ksazd.plan_specifications ps
        where ps.guid = hextoraw(:guid)
    sql
  end

  desc 'Aqua lot test'
  task :aqua_lot do
    require 'models/aqua_lot_builder'
    lot_builder = AquaLotBuilder.new(PLAN_SPEC_GUID, nil)
    ap lot_builder.to_h
  end

  desc 'Contractors list test'
  task :contractors_list do
    require 'models/aqua_lot_builder'
    require 'models/contractors_list_builder'
    lot_builder = AquaLotBuilder.new(PLAN_SPEC_GUID, nil)
    contractors_builder = ContractorsListBuilder.new(lot_builder)
    ap contractors_builder.contractors
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

  require 'db/db'

  def update_project(id, date)
    DB.exec(<<-sql, date, id)
      update ksazd.invest_project_names
        set updated_at = :updated_at
        where aqua_id = :aqua_id
    sql
    DB.commit
  end

  desc 'Update AQUa projects dates'
  task :aqua_projects_dates do
    puts 'Getting project data from AQUA'
    date = Date.new(2013,1,1)
    while date <= Date.today
      puts date
      formatted_date = date.strftime('%d.%m.%Y')
      projects(formatted_date, formatted_date) do |data|
        data.each do |project|
          update_project(project[:spp].to_s, date)
        end
        puts "#{data.size} project(s) updated"
      end
      date += 1
    end
    puts 'Done!'
  end

  desc 'Send AQUa lots test'
  task :send_aqua_lot do
    require 'models/aqua_lot_builder'
    require 'models/contractors_list_builder'
    require 'aqua/lots_endpoint'
    require 'webmock'
    require 'vcr'

    VCR.configure do |c|
      c.cassette_library_dir = 'fixtures/vcr_cassettes'
      c.hook_into :webmock
      c.allow_http_connections_when_no_cassette = true
    end

    lot_builder = AquaLotBuilder.new(PLAN_SPEC_GUID, nil)
    data = lot_builder.to_h
    contractors = ContractorsListBuilder.new(lot_builder).contractors
    data['UCH_KSDAZD_TAB'] = { 'item' => contractors.values }
    response = LotsEndpoint.send('I_LOTS' => { 'item' => data })
    # VCR.use_cassette('lots') do
      puts "response status: #{response.status}"
      puts response.message if response.message
    # end
  end

  desc 'VCR dump'
  task :vcr_to_xml, [:name] do |_, args|
    require 'yaml'
    cassette = YAML.load_file("fixtures/vcr_cassettes/#{args.name}.yml")
    request =  cassette['http_interactions'][0]['request']['body']['string']
    IO.write("fixtures/vcr_cassettes/#{args.name}.xml", request)
  end

  desc 'Monitor lots test'
  task :monitor_lots do
    require 'services/new_lots'
    NewLots.process
  end
end
