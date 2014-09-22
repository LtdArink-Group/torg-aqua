require './db/model'

class PlanSpecification < Model
  ATTRIBUTES = {
    lot_id:      0,
    customer_id: 1
  }.each { |name, index| define_method(name) { @values[index] } }

  private

  def sql
    <<-sql
      select plan_lot_id, customer_id -- 0
        from ksazd.plan_specifications
        where id = #{@id}
    sql
  end
end
