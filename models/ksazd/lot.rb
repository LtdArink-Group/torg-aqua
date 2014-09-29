require './db/model'

class Lot < Model
  attributes :tender_id, :future_plan_id, :next_id
  schema :ksazd
end
