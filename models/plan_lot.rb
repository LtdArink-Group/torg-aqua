require './db/db'

class PlanLot
  def self.find(plan_lot_id)
    self.new(plan_lot_id).tap { |s| s.load }
  end

  def initialize(plan_lot_id)
    @plan_lot_id = plan_lot_id
  end
  
  def load
    sql = <<-sql
      select gkpz_year -- 0
        from ksazd.plan_lots
        where id = #{@plan_lot_id}
    sql
    @plan_lot = DB.query_first_row(sql)
  end

  def gkpz_year
    @plan_lot[0]
  end
end
