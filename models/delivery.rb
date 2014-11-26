require 'db/model'
require 'config/configuration'

class Delivery < Model
  module State
    SUCCESS = 'S'
    ERROR   = 'E'
  end

  ERROR_SQL = <<-sql
    with successfull as
      (select nvl(max(attempted_at), date '2000-01-01') as last_date
        from #{table}
        where state = 'S'
        and aqua_lot_id = :id)
    select min(attempted_at),
           max(d.message) keep (dense_rank last order by attempted_at)
      from deliveries d,
           successfull s
      where d.state = 'E'
        and d.aqua_lot_id = :id
        and d.attempted_at > s.last_date
      group by d.aqua_lot_id
  sql

  def self.first_failed(id)
    values = DB.query_first_row(ERROR_SQL, id, id)
    values ? new(*values) : new(Time.parse('2000-01-01'), '')
  end

  ALL_SQL = <<-sql
    select trunc(attempted_at) as "date", count(distinct aqua_lot_id) value
      from #{table}
      group by trunc(attempted_at)
  sql

  def self.all_stats
    DB.query_all(ALL_SQL)
  end

  ERRORS_SQL = <<-sql
    select trunc(attempted_at) as "date", count(distinct aqua_lot_id) value
      from #{table}
      where state = 'E'
      group by trunc(attempted_at)
  sql

  def self.errors_stats
    DB.query_all(ERRORS_SQL)
  end

  attr_reader :attempted_at, :message

  def initialize(attempted_at, message)
    @attempted_at = attempted_at
    @message = message
  end
end
