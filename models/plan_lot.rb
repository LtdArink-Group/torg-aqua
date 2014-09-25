require './db/model'

class PlanLot < Model
  attributes :gkpz_year, :state, :num_tender, :num_lot,
             :additional_to, :additional_num
  schema :ksazd
end
