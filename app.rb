require 'sinatra'
require './db/db'

get '/' do
  count = DB.exec_query('select count(*) from users').fetch[0].to_i
  "There are #{count} users in db"
end
