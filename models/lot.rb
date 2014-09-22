require './models/plan_lot'
require './models/plan_specification'
require './models/department'

class Lot
  def initialize(plan_spec_id, exec_spec_id)
    @plan_spec_id, @exec_spec_id = plan_spec_id, exec_spec_id
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

  private

  def plan_lot
    @plan_lot ||= PlanLot.find(plan_spec.lot_id)
  end

  def plan_spec
    @plan_spec ||= PlanSpecification.find(@plan_spec_id)
  end
end
