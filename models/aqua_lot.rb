require_relative 'ksazd'
require_relative 'mapping'

class AquaLot
  EI            = 31003 # Заключить договор с единственным поставщиком
  CONTRACT_DONE = 33100 # Договор заключен

  def initialize(plan_spec_id, exec_spec_id)
    @plan_spec_id, @exec_spec_id = plan_spec_id, exec_spec_id
  end

  def to_h
    (public_methods(false) - [:to_h]).map { |a| [a, value(a)] }.to_h
  end

  def plan_lot_id
    plan_spec.guid.bytes.map { |b| "%02X" % b }.join()
  end

  def exec_lot_id
    @exec_spec_id
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

  def state_prog
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

  def status
    (@exec_spec_id && exec_lots.last.status_id == CONTRACT_DONE) ? '2' : '1'
  end

  def organizer
    ksazd_id = plan_lot.department_id
    begin Organizer.find(ksazd_id).aqua_id rescue 'DZO' end
  end

  def commission
    return '' unless plan_lot.commission_id
    type_id = Commission.find(plan_lot.commission_id).commission_type_id
    CommissionType.find(type_id).aqua_id
  end

  def tender_type_plan
    TenderType.find(plan_lot.tender_type_id).aqua_id
  end

  def tender_type_exec
    return '' unless @exec_spec_id
    tender = Tender.find(exec_lots.last.tender_id)
    TenderType.find(tender.tender_type_id).aqua_id
  end

  def tender_type_ei
    return '' unless @exec_spec_id
    exec_lots.last.future_plan_id == EI ? 'EI' : ''
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

  def exec_lots
    @exec_lots ||= [].tap do |lots|
      lots << Lot.find(exec_spec.lot_id)
      while (next_id = lots.last.next_id)
        lots << Lot.find(next_id)
      end
    end
  end

  def exec_spec
    @exec_spec ||= Specification.find(@exec_spec_id)
  end

  def additional_purchase_ratio
    main_lot_cost / additional_purchases_cost_sum
  end

  def main_lot_cost_sum
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
          and l.additional_num <= #{plan_lot.additional_num}
          and l.version = 0
    sql
  end
end
