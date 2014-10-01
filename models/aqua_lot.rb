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
    {
      # Номер лота из КСАЗД (планирование)
      'ZNUMKSAZDP' => plan_spec.guid.bytes.map { |b| "%02X" % b }.join(),
      #Номер лота из КСАЗД (исполнение)
      'ZNUMKSAZDF' => @exec_spec_id,
      # Финансовый год
      'GJAHR' => plan_lot.gkpz_year,
      # Орг.единица
      'ZZCUSTOMER_ID' => customer,
      # Идентификатор (Состояние в ГКПЗ: План / Внеплан)
      'OBJECT_TYPE' => in_plan? ? 'P' : 'V',
      # Раздел ГКПЗ 
      'FUNBUD' => plan_spec.direction,
      # Название лота
      'LNAME' => plan_spec.name,
      # Номер лота
      'LNUM' => "%d.%d" % [plan_lot.num_tender, plan_lot.num_lot],
      # Закупка плановая/внеплановая (+ дозакупка)
      'LPLVP' => lplvp,
      # Статус лота
      'LOTSTATUS' => (@exec_spec_id && last_lot.status_id == CONTRACT_DONE) ? '2' : '1',
      # Организатор процедуры
      'ORG' => organizer,
      # Закупочная комиссия
      'ZK' => comission,
      # Способ закупки (план)
      'SPZKP' => TenderType.find(plan_lot.tender_type_id).aqua_id,
      # Способ закупки (по способу объявления)
      'SPZKF' => begin TenderType.find(last_tender.tender_type_id).aqua_id rescue nil end,
      # Способ закупки (ЕИ по итогам конкурентных процедур)
      'SPZEI' => last_lot.future_plan_id == EI ? 'EI' : nil,
      # Планируемая цена лота (руб. с НДС)
      'SUMN' => plan_spec.cost_nds.to_s('F'),
      # Планируемая цена лота (руб. без  НДС)
      'SUM_' => plan_spec.cost.to_s('F'),
      # Документ, на основании которого определена планируемая цена
      'DOCTYPE' => cost_document,
      # Дата объявления конкурсных процедур. План
      'DATEPK' => format_date(plan_lot.announce_date),
      # Дата вскрытия конвертов. План
      'DATEPV' => format_date(last_tender.bid_date),
      # Дата подведения итогов конкурса. План
      'DATEPI' => format_date(last_tender.summary_date),
      # Дата заключения договора с победителем конкурса. План
      'DATEPD' => format_date(nil)
    }
  end

  private

  # hash values -----------------------------------------------------

  def customer
    ksazd_id = plan_spec.customer_id
    begin
      Department.find(ksazd_id).aqua_id
    rescue
      raise "Не удалось найти заказчика АКВА для id: #{ksazd_id}"
    end
  end

  def lplvp
    plan_lot.additional_to ?
      (in_plan? ? 'D3' : (additional_purchase_ratio < PURCHASE_RATIO ? 'D1' : 'D2')) :
      (in_plan? ? 'P' : 'V')
  end

  def organizer
    ksazd_id = plan_lot.department_id
    begin Organizer.find(ksazd_id).aqua_id rescue 'DZO' end
  end

  def comission
    if plan_lot.commission_id
      type_id = Commission.find(plan_lot.commission_id).commission_type_id
      CommissionType.find(type_id).aqua_id
    end
  end

  def cost_document
    ksazd_name = plan_spec.cost_doc
    begin CostDocument.find(ksazd_name).aqua_id rescue nil end
  end

  # def value(symbol)
  #   send(symbol)
  # rescue Exception => e
  #   "%s: %s" % [e.class, e.message]
  # end

  # entities --------------------------------------------------------

  def plan_lot
    @plan_lot ||= PlanLot.find(plan_spec.plan_lot_id)
  end

  def plan_spec
    @plan_spec ||= PlanSpecification.find(@plan_spec_id)
  end

  def in_plan?
    return @in_plan if defined? @in_plan
    @in_plan = (plan_lot.state == STATE_PLANNED)
  end

  def exec_spec
    @exec_spec ||= Specification.find(@exec_spec_id)
  end

  def exec_lots
    @exec_lots ||= [].tap do |lots|
      lots << Lot.find(exec_spec.lot_id)
      while (next_id = lots.last.next_id)
        lots << Lot.find(next_id)
      end
    end
  end

  def last_lot
    return NullLot.new unless @exec_spec_id
    @last_lot ||= exec_lots.last
  end

  def last_tender
    return NullTender.new unless @exec_spec_id
    @last_tender ||= Tender.find(last_lot.tender_id)
  end

  # helpers ---------------------------------------------------------

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

  def format_date(date)
    date.strftime '%d.%m.%Y' if date
  end
end
