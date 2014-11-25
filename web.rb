require 'sinatra'
require 'sinatra/json'
require 'slim'

$LOAD_PATH << '.'
require 'models/user'
require 'services/projects'
require 'services/new_lots'

get '/' do
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
  AquaLot.pending.map do |lot|
    delivery = Delivery.first_failed(lot.id)
    {
      planSpecGuid: DB.guid(lot.plan_spec_guid),
      specGuid: DB.guid(lot.spec_guid),
      time: delivery.attempted_at,
      message: delivery.message
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
