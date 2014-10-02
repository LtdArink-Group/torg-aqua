require 'sinatra'
require 'sinatra/json'

$LOAD_PATH << '.'
require 'models/user'

before do
  content_type :json
end

get '/users.json' do
  json User.count
end
