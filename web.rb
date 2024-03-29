require 'sinatra'
require 'sinatra/json'
require 'slim'

$LOAD_PATH << '.'
require 'models/user'
require 'services/projects'
require 'services/new_lots'

get '/' do
  headers 'X-UA-Compatible' => 'IE=edge,chrome=1'
  slim :index
end

get '/projects.json' do
  data = {
    count: InvestProjectName.count,
    processedDate: Projects.processed_date,
    lastSyncTime: Projects.last_sync_time
  }
  json data
end

def pending
  AquaLot.pending_with_info.map do |lot|
    {
      planSpecGuid: DB.guid(lot.plan_spec_guid),
      specGuid: DB.guid(lot.spec_guid),
      time: lot.start_time,
      message: lot.message,
      gkpzYear: lot.gkpz_year.to_s,
      department: lot.department,
      direction: lot.direction,
      lotNum: lot.lot_num,
      specName: lot.spec_name,
      tenderId: lot.tender_id.to_i.to_s
    }
  end
end

get '/lots.json' do
  data = {
    count: AquaLot.count,
    lastSyncTime: NewLots.last_sync_time,
    pending: pending
  }
  json data
end

def convert_stats(data)
  data.map { |row| { date: row[0].strftime('%Y-%m-%d'), value: row[1].to_i } }
end

def stats
  [ convert_stats(Delivery.all_stats), convert_stats(Delivery.errors_stats) ]
end

get '/stats.json' do
  json stats
end
