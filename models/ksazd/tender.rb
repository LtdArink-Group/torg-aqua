require 'db/model'

class Tender < Model
  attributes :tender_type_id, :bid_date, :summary_date, :announce_date
  schema :ksazd
end

NullTender = Struct.new(:tender_type_id, :bid_date, :summary_date, :announce_date)
