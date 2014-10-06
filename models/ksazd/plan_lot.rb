require 'db/model'

class PlanLot < Model
  attributes :gkpz_year, :state, :num_tender, :num_lot, :department_id,
             :commission_id, :additional_to, :additional_num,
             :tender_type_id, :etp_address_id, :announce_date
  schema :ksazd
end
