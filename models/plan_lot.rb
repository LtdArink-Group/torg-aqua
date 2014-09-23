require './db/model'

class PlanLot < Model
  ATTRIBUTES = {
    gkpz_year: 0,
    state:     1
  }.each { |name, index| define_method(name) { @values[index] } }

  private

  def sql
    <<-sql
      select gkpz_year, state -- 0
        from ksazd.plan_lots
        where id = #{@id}
    sql
  end
end
