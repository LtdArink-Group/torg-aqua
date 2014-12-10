require 'db/model'
require 'config/configuration'

class Delivery < Model
  module State
    SUCCESS = 'S'
    ERROR   = 'E'
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
