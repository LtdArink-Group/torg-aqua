require './db/db'

class User
  def self.count
    sql = 'select count(*) from ksazd.users'
    DB.query_value(sql).to_i
  end
end
