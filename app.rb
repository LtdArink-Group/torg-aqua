require 'sinatra'
require 'sinatra/json'

require './models/user'

before do
  content_type :json
end

get '/users.json' do
  json count: User.count
end
