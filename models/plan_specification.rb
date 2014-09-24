require './db/model'

class PlanSpecification < Model
  attributes :plan_lot_id, :customer_id, :direction_id
  schema :ksazd

  DIRECTIONS = {
    21002 => 'ТПИР',
    21003 => 'КС',
    21007 => 'НИОКР',
    21011 => 'ИТ'
  }

  def direction
    DIRECTIONS[direction_id]
  end
end
