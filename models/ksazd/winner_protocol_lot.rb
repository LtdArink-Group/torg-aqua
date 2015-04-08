require 'db/model'

class WinnerProtocolLot < Model
  attributes :solution_type_id
  schema :ksazd
  id_fields :winner_protocol_id, :lot_id
end

NullWinnerProtocolLot = Struct.new(:solution_type_id)
