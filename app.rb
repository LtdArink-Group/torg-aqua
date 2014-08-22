require 'sinatra'
require './db/config'

get '/' do
  count = DB.exec_query
  "There are #{count} users in db"
end
