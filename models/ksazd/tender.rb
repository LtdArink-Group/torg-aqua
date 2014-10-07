require 'db/model'

class Tender < Model
  attributes :tender_type_id, :etp_address_id, :announce_date,
             :bid_date, :etp_num, :summary_date
  schema :ksazd
end

NullTender = Struct.new(:tender_type_id, :etp_address_id, :announce_date,
                        :bid_date, :etp_num, :summary_date)
