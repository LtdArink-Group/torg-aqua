require './db/model'

class PlanLot < Model
  attributes :gkpz_year, :state, :num_tender, :num_lot, :department_id,
             :commission_id, :additional_to, :additional_num
  schema :ksazd
end
