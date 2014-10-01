require_relative 'ksazd'
require_relative 'mapping'

class AquaLot
  EI            = 31003 # Заключить договор с единственным поставщиком
  CONTRACT_DONE = 33100 # Договор заключен
  STATE_PLANNED = 1     # План (не Внеплан)
  PURCHASE_RATIO = 0.2  # Дозакупка >< 20%

  def initialize(plan_spec_id, exec_spec_id)
    @plan_spec_id, @exec_spec_id = plan_spec_id, exec_spec_id
  end

  def to_h
    (public_methods(false) - [:to_h]).map { |a| [a.to_s.upcase, value(a)] }.to_h
  end

  # Номер лота из КСАЗД (планирование)
  def znumksazdp
    plan_spec.guid.bytes.map { |b| "%02X" % b }.join()
  end

  #Номер лота из КСАЗД (исполнение)
  def znumksazdf
    @exec_spec_id
  end

  # Финансовый год 
  def gjahr
    plan_lot.gkpz_year
  end

  # Орг.единица
  def zzcustomer_id
    ksazd_id = plan_spec.customer_id
    begin
      Department.find(ksazd_id).aqua_id
    rescue
      raise "Не удалось найти заказчика АКВА для id: #{ksazd_id}"
    end
  end

  # Идентификатор (Состояние в ГКПЗ: План / Внеплан)
  def object_type
    in_plan? ? 'P' : 'V'
  end

  # Раздел ГКПЗ 
  def funbud
    plan_spec.direction
  end

  # Название лота
  def lname
    plan_spec.name
  end

  # Номер лота
  def lnum
    "%d.%d" % [plan_lot.num_tender, plan_lot.num_lot]
  end

  # Закупка плановая/внеплановая (+ дозакупка)
  def lplvp
    plan_lot.additional_to ?
      (in_plan? ? 'D3' : (additional_purchase_ratio < PURCHASE_RATIO ? 'D1' : 'D2')) :
      (in_plan? ? 'P' : 'V')
  end

  # Статус лота
  def lotstatus
    (@exec_spec_id && last_lot.status_id == CONTRACT_DONE) ? '2' : '1'
  end

  # Организатор процедуры
  def org
    ksazd_id = plan_lot.department_id
    begin Organizer.find(ksazd_id).aqua_id rescue 'DZO' end
  end

  # Закупочная комиссия
  def zk
    return nil unless plan_lot.commission_id
    type_id = Commission.find(plan_lot.commission_id).commission_type_id
    CommissionType.find(type_id).aqua_id
  end

  # Способ закупки (план)
  def spzkp
    TenderType.find(plan_lot.tender_type_id).aqua_id
  end

  # Способ закупки (по способу объявления)
  def spzkf
    begin TenderType.find(last_tender.tender_type_id).aqua_id rescue nil end
  end

  # Способ закупки (ЕИ по итогам конкурентных процедур)
  def spzei
    return '' unless @exec_spec_id
    last_lot.future_plan_id == EI ? 'EI' : nil
  end

  # Планируемая цена лота (руб. с НДС)
  def sumn
    plan_spec.cost_nds.to_s('F')
  end

  # Планируемая цена лота (руб. без  НДС)
  def sum_
    plan_spec.cost.to_s('F')
  end

  # Документ, на основании которого определена планируемая цена
  def doctype
    ksazd_name = plan_spec.cost_doc
    begin CostDocument.find(ksazd_name).aqua_id rescue nil end
  end

  # Дата объявления конкурсных процедур. План
  def datepk
    format_date(plan_lot.announce_date)
  end

  # Дата вскрытия конвертов. План
  def datepv
    format_date(last_tender.bid_date)
  end

  # Дата подведения итогов конкурса. План
  def datepi
    format_date(last_tender.summary_date)
  end

  # Дата заключения договора с победителем конкурса. План
  def datepd
    format_date(nil)
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

  def in_plan?
    return @in_plan if defined? @in_plan
    @in_plan = (plan_lot.state == STATE_PLANNED)
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

  def last_lot
    return NullLot.new unless @exec_spec_id
    @last_lot ||= exec_lots.last
  end

  def last_tender
    return NullTender.new unless @exec_spec_id
    @last_tender ||= Tender.find(last_lot.tender_id)
  end

  def format_date(date)
    date.strftime '%d.%m.%Y' if date
  end
end
