require 'db/model'
require 'config/configuration'

class Delivery < Model
  module State
    SUCCESS = 'S'
    ERROR   = 'E'
  end

  LAST_SUCCESSFUL_SQL = <<-sql
    select max(attempted_at)
      from #{table}
      where state = 'S'
        and aqua_lot_id = :id
  sql

  ERROR_SQL = <<-sql
    select min(attempted_at),
           max(message) keep (dense_rank last order by attempted_at)
      from #{table}
      where state = 'E'
        and aqua_lot_id = :id
        and attempted_at > to_date(:time, 'YYYY-MM-DD HH24:MI:SS')
      group by aqua_lot_id
  sql

  def self.first_failed(id)
    last_successful = DB.query_value(LAST_SUCCESSFUL_SQL, id)
    time = last_successful ? last_successful : Configuration.integration.lot.start_time
    time = time.strftime('%Y-%m-%d %H:%M:%S')
    values = DB.query_first_row(ERROR_SQL, id, time)
    new(*values)
  end

  attr_reader :attempted_at, :message

  def initialize(attempted_at, message)
    @attempted_at = attempted_at
    @message = message
  end
end
