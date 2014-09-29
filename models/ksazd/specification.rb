require './db/model'

class Specification < Model
  attributes :lot_id, :plan_specification_id
  schema :ksazd
end
