require 'db/model'

class PlanSpecification < Model
  attributes :plan_lot_id, :guid, :name, :qty, :cost, :cost_nds, :cost_doc,
             :unit_id, :okdp_id, :okved_id, :direction_id, :customer_id,
             :monitor_service_id, :delivery_date_begin, :delivery_date_end,
             :requirements, :curator, :tech_curator
  schema :ksazd
end
