require 'models/aqua_lot_builder'
require 'models/contractors_list_builder'
require 'aqua/lots_endpoint'
require 'webmock'
require 'vcr'

GUID = ['86C7DEF9C6DF82BD61B4799DE52B4F3A'].pack('H*')

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
end

namespace :aqua do
  def send_lot
    lot_builder = AquaLotBuilder.new(GUID, nil)
    data = lot_builder.to_h
    contractors = ContractorsListBuilder.new(lot_builder).contractors
    data['UCH_KSDAZD_TAB'] = { 'item' => contractors.values }
    yield data
    response = LotsEndpoint.send('I_LOTS' => { 'item' => data })
    # VCR.use_cassette('lots') do
      puts "response status: #{response.status}"
      puts response.message if response.message
    # end
  end

  desc 'New project'
  task :new_lot do
    send_lot { |_| }
  end

  desc 'Lot for existing GKPZ program'
  task :existing_gkpz do
    send_lot do |data|
      data['LNUM'] = '100.500'
      data['ZNUMKSAZDP'] = Base64.encode64(['2A691E8148F136A2D737F3FD52DBDB51'].pack('H*')).chop
    end
  end

  desc 'New contragent for lot'
  task :new_contragent do
    send_lot do |data|
      data['UCH_KSDAZD_TAB']['item'] << {
        'ZNUMC1C' => '2', 'PARTNER_NAME' => 'test', 'INN' => '990099009901', 'KPP' => '991122333',
        'ALT_OFFER' => '', 'PLANU' => 'X', 'REGZP' => '', 'PODZA' => '',
        'OTKL' => '', 'ZOZ' => '', 'ZNPP' => '', 'POBED' => '',
        'ZSUM' => '0', 'ZSUMWOVAT' => '0', 'PSUM' => '0', 'PSUMWOVAT' => '0',
        'PERETORG' => 'false', 'PKOL' => 0
      }
    end
  end

  desc 'Change plan to unplan'
  task :change_plan do
    send_lot do |data|
      data['OBJECT_TYPE'] = 'V'
      data['LPLVP'] = 'V'
    end
  end

  desc 'Delete lot'
  task :delete do
    send_lot do |data|
      data['LOTDEL'] = 'X'
    end
  end

  desc 'Contractors less than 3'
  task :err_less_than_3 do
    send_lot do |data|
      data['UCH_KSDAZD_TAB']['item'] = data['UCH_KSDAZD_TAB']['item'][0, 2]
    end
  end

  desc 'Contractors less than 1 for EI'
  task :err_less_than_1 do
    send_lot do |data|
      data['SPZKP'] = 'EI'
      data['SPZKF'] = 'EI'
      data['SPZEI'] = 'EI'
      data['P_REASON_DOC'] = 'foo'
      data['UCH_KSDAZD_TAB']['item'] = []
    end
  end

  desc 'Planned cost with VAT less than financing'
  task :err_cost_nds do
    send_lot do |data|
      data['SUMN'] = 1
    end
  end

  desc 'Planned cost without VAT less than spending'
  task :err_cost do
    send_lot do |data|
      data['SUM_'] = 1000000
    end
  end

  desc 'Wrong project number'
  task :err_project do
    send_lot do |data|
      data['SPP'] = 'T-9999-99999'
    end
  end

  desc 'No mandatory data'
  task :err_mandatory do
    send_lot do |data|
      data.each_key { |key| data[key] = '' unless key == 'UCH_KSDAZD_TAB' }
    end
  end

  desc 'VCR dump'
  task :vcr_to_xml, [:name] do |_, args|
    require 'yaml'
    cassette = YAML.load_file("fixtures/vcr_cassettes/#{args.name}.yml")
    request =  cassette['http_interactions'][0]['request']['body']['string']
    IO.write("fixtures/vcr_cassettes/#{args.name}.xml", request)
  end
end
