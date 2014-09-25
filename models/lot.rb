require './models/plan_lot'
require './models/plan_specification'
require './models/department'

class Lot
  def initialize(plan_spec_id, exec_spec_id)
    @plan_spec_id, @exec_spec_id = plan_spec_id, exec_spec_id
  end

  def to_h
    (public_methods(false) - [:to_h]).map { |a| [a, value(a)] }.to_h
  end

  def gkpz_year
    plan_lot.gkpz_year
  end

  def department
    ksazd_id = plan_spec.customer_id
    begin
      Department.find(ksazd_id).aqua_id
    rescue
      raise "Не удалось найти заказчика АКВА для id: #{ksazd_id}"
    end
  end

  def state
    plan_lot.state == 1 ? 'P' : 'V'
  end

  def direction
    plan_spec.direction
  end

  def name
    plan_spec.name
  end

  def number
    "%d.%d" % [plan_lot.num_tender, plan_lot.num_lot]
  end

  def state_lot
    plan_lot.additional_to ?
      (plan_lot.state == 1 ? 'D3' : (additional_purchase_ratio < 0.2 ? 'D1' : 'D2')) :
      (plan_lot.state == 1 ? 'P' : 'V')
  end

  private

  def value(symbol)
    send(symbol)
  rescue Exception => e
    "%s: %s" % [e.class, e.message]
  end

  def plan_lot
    @plan_lot ||= PlanLot.find(plan_spec.plan_lot_id)
  end

  def plan_spec
    @plan_spec ||= PlanSpecification.find(@plan_spec_id)
  end

  def additional_purchase_ratio
    lot_cost_sum / additional_purchases_cost_sum
  end

  def lot_cost_sum
    DB.query_value(<<-sql)
      select sum(s.cost_nds)
        from ksazd.plan_specifications s,
             ksazd.plan_lots l
        where s.plan_lot_id = l.id
          and l.guid = '#{plan_lot.additional_to}'
          and l.version = 0
    sql
  end

  def additional_purchases_cost_sum
    DB.query_value(<<-sql)
      select sum(s.cost_nds)
        from ksazd.plan_specifications s,
             ksazd.plan_lots l
        where s.plan_lot_id = l.id
          and l.additional_to = #{plan_lot.additional_to}
          and l.additional_num >= #{plan_lot.additional_num}
          and l.version = 0
    sql
  end
end
