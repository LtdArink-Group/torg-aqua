require 'models/ksazd'
require 'models/mapping'

class AquaLot
  EI            = 31003 # Заключить договор с единственным поставщиком
  CONTRACT_DONE = 33100 # Договор заключен
  STATE_PLANNED = 1     # План (не Внеплан)
  ADDITIONAL_RATIO = 0.2 # Дозакупка >< 20%
  DIRECTIONS = {
    21002 => 'ТПИР',
    21003 => 'КС',
    21007 => 'НИОКР',
    21011 => 'ИТ'
  }

  def initialize(plan_spec_id, exec_spec_id)
    @plan_spec_id, @exec_spec_id = plan_spec_id, exec_spec_id
  end

  def to_h
    {
      # Номер лота из КСАЗД (планирование)
      'ZNUMKSAZDP' => format_guid(plan_spec.guid),
      #Номер лота из КСАЗД (исполнение)
      'ZNUMKSAZDF' => @exec_spec_id,
      # Финансовый год
      'GJAHR' => plan_lot.gkpz_year,
      # Орг.единица
      'ZZCUSTOMER_ID' => customer,
      # Идентификатор (Состояние в ГКПЗ: План / Внеплан)
      'OBJECT_TYPE' => lot_state,
      # Раздел ГКПЗ 
      'FUNBUD' => DIRECTIONS[plan_spec.direction_id],
      # Название лота
      'LNAME' => plan_spec.name,
      # Номер лота
      'LNUM' => "%d.%d" % [plan_lot.num_tender, plan_lot.num_lot],
      # Закупка плановая/внеплановая (+ дозакупка)
      'LPLVP' => plan_lot.additional_to ? additional_state : lot_state,
      # Статус лота
      'LOTSTATUS' => (@exec_spec_id && last_lot.status_id == CONTRACT_DONE) ? '2' : '1',
      # Организатор процедуры
      'ORG' => Organizer.lookup(plan_lot.department_id) || 'DZO',
      # Закупочная комиссия
      'ZK' => comission,
      # Способ закупки (план)
      'SPZKP' => TenderType.lookup(plan_lot.tender_type_id),
      # Способ закупки (по способу объявления)
      'SPZKF' => TenderType.lookup(last_tender.tender_type_id),
      # Способ закупки (ЕИ по итогам конкурентных процедур)
      'SPZEI' => last_lot.future_plan_id == EI ? 'EI' : nil,
      # Планируемая цена лота (руб. с НДС)
      'SUMN' => (plan_spec.cost_nds * plan_spec.qty).to_s('F'),
      # Планируемая цена лота (руб. без  НДС)
      'SUM_' => (plan_spec.cost * plan_spec.qty).to_s('F'),
      # Документ, на основании которого определена планируемая цена
      'DOCTYPE' => CostDocument.lookup(plan_spec.cost_doc),
      # Дата объявления конкурсных процедур. План
      'DATEPK' => format_date(plan_lot.announce_date),
      # Дата вскрытия конвертов. План
      'DATEPV' => format_date(last_tender.bid_date),
      # Дата подведения итогов конкурса. План
      'DATEPI' => format_date(last_tender.summary_date),
      # Дата заключения договора с победителем конкурса. План
      'DATEPD' => format_date(nil),
      # Дата объявления конкурсных процедур. Факт
      'DATEFK' => format_date(last_tender.announce_date),
      # Дата вскрытия конвертов. Факт
      'DATEFV' => format_date(open_protocol.open_date),
      # Дата подведения итогов конкурса. Факт
      'DATEFI' => format_date(winner_protocol.confirm_date),
      # Дата заключения договора с победителем конкурса. Факт
      'DATEFD' => format_date(contract.confirm_date),
      # Ссылка на лот по дозакупке
      'SSLOT' => format_guid(additional_to)
    }
  end

  private

  # hash values -----------------------------------------------------

  def customer
    ksazd_id = plan_spec.customer_id
    Department.lookup(ksazd_id) ||
      begin raise "Не удалось найти заказчика АКВА для id: #{ksazd_id}" end
  end

  def comission
    if plan_lot.commission_id
      type_id = Commission.find(plan_lot.commission_id).commission_type_id
      CommissionType.lookup(type_id)
    end
  end

  # entities --------------------------------------------------------

  def plan_lot
    @plan_lot ||= PlanLot.find(plan_spec.plan_lot_id)
  end

  def plan_spec
    @plan_spec ||= PlanSpecification.find(@plan_spec_id)
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

  def open_protocol
    return NullOpenProtocol.new unless @exec_spec_id
    OpenProtocol.find(last_lot.tender_id) || NullOpenProtocol.new
  end

  def winner_protocol
    return NullContract.new unless @exec_spec_id
    Contract.find(last_lot.winner_protocol_id) || NullContract.new
  end

  def contract
    return NullWinnerProtocol.new unless @exec_spec_id
    WinnerProtocol.find(last_lot.id) || NullWinnerProtocol.new
  end

  # helpers ---------------------------------------------------------

  def in_plan?
    return @in_plan if defined? @in_plan
    @in_plan = (plan_lot.state == STATE_PLANNED)
  end

  def lot_state
    in_plan? ? 'P' : 'V'
  end

  def additional_state
    if in_plan?
      'D3'
    else
      additional_ratio < ADDITIONAL_RATIO ? 'D1' : 'D2'
    end
  end

  def additional_ratio
    main_lot_cost / additional_cost_sum
  end

  def main_lot_cost
    DB.query_value(<<-sql)
      select sum(s.cost_nds * s.qty)
        from ksazd.plan_specifications s,
             ksazd.plan_lots l
        where s.plan_lot_id = l.id
          and l.guid = '#{plan_lot.additional_to}'
          and l.version = 0
    sql
  end

  def additional_cost_sum
    DB.query_value(<<-sql)
      select sum(s.cost_nds * s.qty)
        from ksazd.plan_specifications s,
             ksazd.plan_lots l
        where s.plan_lot_id = l.id
          and l.additional_to = #{plan_lot.additional_to}
          and l.additional_num <= #{plan_lot.additional_num}
          and l.version = 0
    sql
  end

  def additional_to
    return nil unless plan_lot.additional_to
    DB.query_value(<<-sql)
      select distinct s.guid
        from ksazd.plan_specifications s
        where s.direction_id = #{plan_spec.direction_id}
          and s.plan_lot_id = #{plan_spec.plan_lot_id}
    sql
  end

  def format_date(date)
    date.strftime '%d.%m.%Y' if date
  end

  def format_guid(guid)
    guid.bytes.map { |b| "%02X" % b }.join if guid
  end
end
