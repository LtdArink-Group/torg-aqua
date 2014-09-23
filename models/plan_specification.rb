require './db/model'

class PlanSpecification < Model
  ATTRIBUTES = {
    lot_id:       0,
    customer_id:  1,
    direction_id: 2
  }.each { |name, index| define_method(name) { @values[index] } }

  DIRECTIONS = {
    21002 => 'ТПИР',
    21003 => 'КС',
    21007 => 'НИОКР',
    21011 => 'ИТ'
  }

  def direction
    DIRECTIONS[direction_id]
  end

  private

  def sql
    <<-sql
      select plan_lot_id, customer_id, direction_id -- 0
        from ksazd.plan_specifications
        where id = #{@id}
    sql
  end
end
