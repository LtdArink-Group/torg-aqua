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

  private

  def value(symbol)
    send(symbol)
  rescue Exception => e
    "#{e.class}: #{e.message}"
  end

  def plan_lot
    @plan_lot ||= PlanLot.find(plan_spec.lot_id)
  end

  def plan_spec
    @plan_spec ||= PlanSpecification.find(@plan_spec_id)
  end
end
