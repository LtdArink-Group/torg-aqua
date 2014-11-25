require 'sinatra'
require 'sinatra/json'
require 'slim'

$LOAD_PATH << '.'
require 'models/user'
require 'services/projects'

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

get '/users.json' do
  json User.count
end
