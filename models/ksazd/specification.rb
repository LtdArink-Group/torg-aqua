require 'db/model'

class Specification < Model
  attributes :qty, :cost, :cost_nds, :lot_id, :plan_specification_id
  schema :ksazd
end
