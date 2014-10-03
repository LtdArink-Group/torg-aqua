require 'db/model'

class PlanSpecification < Model
  attributes :guid, :plan_lot_id, :customer_id, :direction_id, :name,
             :qty, :cost, :cost_nds, :cost_doc
  schema :ksazd
end
