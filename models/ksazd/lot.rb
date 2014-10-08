require 'db/model'

class Lot < Model
  attributes :id, :tender_id, :status_id, :winner_protocol_id,
             :future_plan_id, :next_id, :non_public_reason,
             :non_contract_reason
  schema :ksazd
end

NullLot = Struct.new(:id, :tender_id, :status_id, :winner_protocol_id,
                     :future_plan_id, :next_id, :non_public_reason,
                     :non_contract_reason)
