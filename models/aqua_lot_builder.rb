require 'models/ksazd'
require 'models/mapping'
require 'bigdecimal'
require 'base64'

class AquaLotBuilder
  ZERO = BigDecimal.new('0')
  # ИС КСАЗД
  FUTURE_PLAN_EI   = 31003 # Заключить договор с единственным поставщиком
  CONTRACT_DONE    = 33100 # Договор заключен
  FRUSTRATED       = 33110 # Признана несостоявшейся
  STATE_PLANNED    = 1     # План (не Внеплан)
  ADDITIONAL_RATIO = 0.2   # Дозакупка >< 20%
  CANCELLED        = 15004 # Отменен
  EXCLUDED         = 15007 # Исключен СД
  # ИС АКВа
  STATE_PLAN            = 'P'  # Плановая закупка
  STATE_UNPLAN          = 'V'  # Внеплановая закупка
  STATE_ADD_PLAN        = 'D3' # Плановая дозакупка
  STATE_ADD_UNPLAN_LESS = 'D1' # Внеплановая дозакупка менее 20%
  STATE_ADD_UNPLAN_MORE = 'D2' # Внеплановая дозакупка более 20%
  IN_PROGRESS       = 1    # В работе
  TENDER_COMPLETED  = 2    # Закупка проведена
  TENDER_FRUSTRATED = 4    # Несостоявшаяся закупка
  AQUA_DZO         = 'DZO' # Организатор процедуры (по умолчанию)
  AQUA_EI          = 'EI'  # Способ закупки ЕИ
  INVESTMENTS      = '001' # Инвестиционные средства
  OTHER            = 4     # Раздел контрактного пакета "Прочее"
  RUSSIAN_RUBLE    = 'RUB' # Код валюты

  attr_reader :plan_spec_guid, :spec_guid

  def initialize(plan_spec_guid, spec_guid)
    @plan_spec_guid = plan_spec_guid
    @spec_guid = spec_guid
  end

  def to_h
    {
      # Финансовый год
      'GJAHR' => plan_lot.gkpz_year,
      # Орг.единица
      'ZZCUSTOMER_ID' => customer,
      # Идентификатор (Состояние в ГКПЗ: План / Внеплан)
      'OBJECT_TYPE' => lot_state,
      # Статус
      'STATUS' => IN_PROGRESS,
      # Раздел ГКПЗ 
      'FUNBUD' => Direction.lookup(plan_spec.direction_id),
      # Код валюты
      'WAERS' => RUSSIAN_RUBLE,
      # Внутренний номер инвестиционного проекта
      'SPP' => invest_project || 'T-4070-00083',
      # Название лота
      'LNAME' => plan_spec.name,
      # Номер лота
      'LNUM' => format('%d.%d', plan_lot.num_tender, plan_lot.num_lot),
      # Закупка плановая/внеплановая (+ дозакупка)
      'LPLVP' => plan_lot.additional_to ? additional_state : lot_state,
      # Статус лота
      'LOTSTATUS' => lotstatus,
      # метка удаления
      'LOTDEL' => [CANCELLED, EXCLUDED].include?(plan_lot.state) ? 'X' : '',
      # Организатор процедуры
      'ORG' => Organizer.lookup(plan_lot.department_id) || AQUA_DZO,
      # Закупочная комиссия
      'ZK' => comission,
      # Способ закупки (план)
      'SPZKP' => TenderType.lookup(plan_lot.tender_type_id),
      # Способ закупки (по способу объявления)
      'SPZKF' => TenderType.lookup(tender.tender_type_id) || '',
      # Способ закупки (ЕИ по итогам конкурентных процедур)
      'SPZEI' => lot.future_plan_id == FUTURE_PLAN_EI ? AQUA_EI : '',
      # Планируемая цена лота (руб. с НДС)
      'SUMN' => format_cost(cost_nds),
      # Планируемая цена лота (руб. без  НДС)
      'SUM_' => format_cost(cost),
      # Документ, на основании которого определена планируемая цена
      'DOCTYPE' => CostDocument.lookup(plan_spec.cost_doc),
      # Дата объявления конкурсных процедур. План
      'DATEPK' => format_date(plan_lot.announce_date),
      # Дата вскрытия конвертов. План
      'DATEPV' => format_date(tender.bid_date),
      # Дата подведения итогов конкурса. План
      'DATEPI' => format_date(tender.summary_date),
      # Дата заключения договора с победителем конкурса. План
      'DATEPD' => format_date(nil),
      # Дата объявления конкурсных процедур. Факт
      'DATEFK' => format_date(tender.announce_date),
      # Дата вскрытия конвертов. Факт
      'DATEFV' => format_date(open_protocol.open_date),
      # Дата подведения итогов конкурса. Факт
      'DATEFI' => format_date(winner_protocol.confirm_date),
      # Дата заключения договора с победителем конкурса. Факт
      'DATEFD' => format_date(contract.confirm_date),
      # Ссылка на лот по дозакупке
      'SSLOT' => format_guid(additional_to),
      # Источник финансирования
      'FIN_GROUP' => INVESTMENTS,
      # Использование электронной торговой площадки b2b.enegro План
      'B2BP' => EtpAddress.lookup(plan_lot.etp_address_id),
      # Использование электронной торговой площадки b2b.enegro План
      'B2BF' => EtpAddress.lookup(tender.etp_address_id),
      # Подразделение - куратор закупки
      'ZKURATOR' => zkurator,
      # Дата начала поставки товаров, выполнения работ, услуг
      'DATENP' => format_date(plan_spec.delivery_date_begin),
      # Дата окончания поставки товаров, выполнения работ, услуг
      'DATEOP' => format_date(plan_spec.delivery_date_end),
      # Куратор
      'KURATOR' => plan_spec.curator,
      # Технический куратор
      'TKURATOR' => plan_spec.tech_curator,
      # Подраздел ГКПЗ
      'L_FUNBUD' => Subdirection.lookup(plan_spec.direction_id,
                                        plan_lot.subject_type_id),
      # Обоснование (в случае ЕИ или отклонения от регламентных порогов)
      'P_REASON' => plan_lot.tender_type_explanations || '',
      # Обоснование (документ)
      'P_REASON_DOC' => plan_lot.explanations_doc || '',
      # Пункт положения
      'P_PARAGRAPH' => paragraph,
      # Количество
      'ZEI' => plan_spec.qty,
      # ОКЕИ
      'OKEI' => Unit.lookup(plan_spec.unit_id),
      # ОКАТО
      'OKATO' => okato[0, 8],
      # Код по ОКВЭД
      'ZOKVED' => OKVED.lookup(plan_spec.okved_id),
      # Код по ОКДП
      'ZOKPD' => OKDP.lookup(plan_spec.okdp_id),
      # Мин. необходимые требования, предъявляемые к закупаеой продукции
      'ZMTREB' => plan_spec.requirements,
      # Раздел контрактного пакета
      'SEQ' => OTHER,
      # Причины невыполнения сроков объявления о процедуре и вскр. конвертов,
      # Реквизиты протокола ЦЗК в случае отмены закупки
      'PRN1' => prn1,
      # Причины невыполнения срока заключения договора
      'PRN2' => lot.non_contract_reason || '',
      # Код валюты
      'L_WAERS' => RUSSIAN_RUBLE,
      # Номер процедуры на ЭТП
      'ZNUMPR' => tender.etp_num || '',
      # Номер лота из КСАЗД
      'ZNUMKSAZDP' => format_guid(spec_guid || plan_spec_guid),
      # Номер лота из КСАЗД (исполнение)
      # 'ZNUMKSAZDF' => '',
      # Планируемый объем обязательств (финансирование с НДС)
      'FINSN5Y1' => format_cost(plan_spec_amounts[0][0]),
      'FINSN5Y2' => format_cost(plan_spec_amounts[1][0]),
      'FINSN5Y3' => format_cost(plan_spec_amounts[2][0]),
      'FINSN5Y4' => format_cost(plan_spec_amounts[3][0]),
      'FINSN5Y5' => format_cost(plan_spec_amounts[4][0]),
      # Планируемая сумма освоения (без НДС)
      'OSVBN5Y1' => format_cost(plan_spec_amounts[0][1]),
      'OSVBN5Y2' => format_cost(plan_spec_amounts[1][1]),
      'OSVBN5Y3' => format_cost(plan_spec_amounts[2][1]),
      'OSVBN5Y4' => format_cost(plan_spec_amounts[3][1]),
      'OSVBN5Y5' => format_cost(plan_spec_amounts[4][1]),
      # Планируемая сумма освоения (с НДС)
      'OSVSN5Y1' => format_cost(plan_spec_amounts[0][2]),
      'OSVSN5Y2' => format_cost(plan_spec_amounts[1][2]),
      'OSVSN5Y3' => format_cost(plan_spec_amounts[2][2]),
      'OSVSN5Y4' => format_cost(plan_spec_amounts[3][2]),
      'OSVSN5Y5' => format_cost(plan_spec_amounts[4][2])
    }
  end

  def plan_lot_id
    plan_spec.plan_lot_id
  end

  def exec_spec_id
    spec_id
  end

  def cost_nds
    spec_guid ? spec
    plan_spec.cost_nds - framed_cost_nds
  end

  def cost
    plan_spec.cost - framed_cost
  end

  private

  # hash values -----------------------------------------------------

  def customer
    ksazd_id = plan_spec.customer_id
    Department.lookup(ksazd_id) or
      fail "Не удалось найти заказчика АКВА для id: #{ksazd_id}"
  end

  def invest_project
    invest_project_name_id =
      InvestProject.find(plan_spec.invest_project_id).invest_project_name_id
    InvestProjectName.lookup(invest_project_name_id)
  end

  def lotstatus
    case lot.status_id
    when FRUSTRATED then TENDER_FRUSTRATED
    when CONTRACT_DONE then TENDER_COMPLETED
    else IN_PROGRESS
    end
  end

  def comission
    return '' unless plan_lot.commission_id
    type_id = Commission.find(plan_lot.commission_id).commission_type_id
    CommissionType.lookup(type_id)
  end

  def zkurator
    ksazd_id = plan_spec.monitor_service_id
    value = MonitorService.lookup(ksazd_id) or
      fail "Не удалось найти куратора АКВА для id: #{ksazd_id}"
    sprintf('%03d', value)
  end

  def paragraph
    num = plan_lot.point_clause.scan(/5\.9\.1\.([1-5])/)[0]
    num ? "00#{num}" : ''
  end

  def prn1
    [].tap do |a|
      if reason = lot.non_public_reason
        a << reason
      end
      if id = plan_lot.protocol_id
        a << Protocol.find(id).details
      end
    end.join ' / '
  end

  # entities --------------------------------------------------------

  def plan_spec
    @plan_spec ||= PlanSpecification.find(plan_spec_id)
  end

  def plan_lot
    @plan_lot ||= PlanLot.find(plan_spec.plan_lot_id)
  end

  def spec
    @spec ||= Specification.find(spec_id)
  end

  def lot
    return NullLot.new unless spec_id
    @lot ||= Lot.find(spec.lot_id)
  end

  def tender
    return NullTender.new unless spec_id
    @tender ||= Tender.find(lot.tender_id)
  end

  def open_protocol
    return NullOpenProtocol.new unless spec_id
    OpenProtocol.find(lot.tender_id) || NullOpenProtocol.new
  end

  def winner_protocol
    return NullWinnerProtocol.new unless spec_id
    WinnerProtocol.find(lot.winner_protocol_id) || NullWinnerProtocol.new
  end

  def contract
    return NullContract.new unless spec_id
    Contract.find(lot.id) || NullContract.new
  end

  # helpers ---------------------------------------------------------

  def in_plan?
    return @in_plan if defined? @in_plan
    @in_plan = (plan_lot.state == STATE_PLANNED)
  end

  def lot_state
    in_plan? ? STATE_PLAN : STATE_UNPLAN
  end

  def additional_state
    in_plan? ? STATE_ADD_PLAN : additional_unplan_state
  end

  def additional_unplan_state
    if additional_ratio < ADDITIONAL_RATIO
      STATE_ADD_UNPLAN_LESS
    else
      STATE_ADD_UNPLAN_MORE
    end
  end

  def additional_ratio
    main_lot_cost / additional_cost_sum
  end

  def plan_spec_amounts
    @plan_spec_amounts ||= plan_spec_amounts_from_db.tap do |a|
      (5 - a.size).times { a << Array.new(3, ZERO) }
    end
  end

  def format_date(time)
    time ? time.to_date : ''
  end

  def format_guid(guid)
    guid ? Base64.encode64(guid).chop : ''
  end

  def format_cost(cost)
    cost.to_s('F')
  end

  # data access -----------------------------------------------------

  class << self
    def commission_types
      Configuration.integration.lot.commission_types.join(',')
    end

    def plan_statuses
      Configuration.integration.lot.plan_statuses.join(',')
    end
  end

  PLAN_SPEC_SQL = <<-sql
    select max(ps.id)
      from ksazd.protocols p,
           ksazd.commissions c,
           ksazd.plan_lots pl,
           ksazd.plan_specifications ps
      where p.commission_id = c.id
        and p.id = pl.protocol_id
        and pl.id = ps.plan_lot_id
        --
        and c.commission_type_id in (#{commission_types})
        and pl.status_id in (#{plan_statuses})
        and ps.guid = hextoraw(:guid)
      group by ps.guid
  sql

  def plan_spec_id
    @plan_spec_id ||= DB.query_value(PLAN_SPEC_SQL, DB.guid(plan_spec_guid)).to_i
  end

  SPEC_ID_FROM_PLAN_SQL = <<-sql
    select s.id
      from ksazd.specifications s,
           ksazd.lots l
      where s.lot_id = l.id
        and l.next_id is null
        and s.plan_specification_id = :plan_spec_id
  sql

  SPEC_ID_SQL = <<-sql
    select s.id
      from ksazd.specifications s,
           ksazd.lots l
      where s.lot_id = l.id
        and l.next_id is null
        and s.guid = hextoraw(:guid)
  sql

  def spec_id
    @spec_id ||=
      if spec_guid
        DB.query_value(SPEC_ID_SQL, spec_guid).to_i
      else
        values = DB.query_first_row(SPEC_ID_FROM_PLAN_SQL, plan_spec_id)
        values[0].to_i if values
      end
  end

  MAIN_LOT_COST_SQL = <<-sql
    select sum(s.cost_nds * s.qty)
      from ksazd.plan_specifications s,
           ksazd.plan_lots l
      where s.plan_lot_id = l.id
        and l.guid = hextoraw(:guid)
        and l.version = 0
  sql

  def main_lot_cost
    DB.query_value(MAIN_LOT_COST_SQL, DB.guid(plan_lot.additional_to))
  end

  ADDITIONAL_COST_SUM_SQL = <<-sql
    select sum(s.cost_nds * s.qty)
      from ksazd.plan_specifications s,
           ksazd.plan_lots l
      where s.plan_lot_id = l.id
        and l.additional_to = hextoraw(:guid)
        and l.additional_num <= :num
        and l.version = 0
  sql

  def additional_cost_sum
    guid = DB.guid(plan_lot.additional_to)
    DB.query_value(ADDITIONAL_COST_SUM_SQL, guid, plan_lot.additional_num)
  end

  ADDITIONAL_TO_SQL = <<-sql
    select distinct s.guid
      from ksazd.plan_specifications s,
           ksazd.plan_lots l
      where s.plan_lot_id = l.id
        and s.direction_id = :direction_id
        and l.guid = hextoraw(:guid)
  sql

  def additional_to
    return '' unless plan_lot.additional_to
    guid = DB.guid(plan_lot.additional_to)
    DB.query_value(ADDITIONAL_TO_SQL, plan_spec.direction_id, guid)
  end

  OKATO_SQL = <<-sql
    select nvl(h.okato, a.okato)
      from ksazd.fias_plan_specifications s,
           ksazd.fias_houses h,
           ksazd.fias_addrs a
      where s.houseid = h.houseid(+)
        and s.addr_aoid = a.aoid
        and s.plan_specification_id = :id
  sql

  def okato
    DB.query_value(OKATO_SQL, plan_spec_id)
  end

  PLAN_SPEC_AMOUNTS_SQL = <<-sql
    select a.amount_finance_nds, a.amount_mastery, a.amount_mastery_nds
      from ksazd.plan_spec_amounts a
      where a.plan_specification_id = :id
      order by a.year
  sql

  def plan_spec_amounts_from_db
    DB.query_all(PLAN_SPEC_AMOUNTS_SQL, plan_spec_id)
  end

  def framed_cost_nds
    framed_costs[0] || 0
  end

  def framed_cost
    framed_costs[1] || 0
  end

  FRAMED_COSTS_SQL = <<-sql
    select sum(s.cost_nds), sum(s.cost)
      from ksazd.specifications s,
           ksazd.lots l
      where s.lot_id = l.id
        and l.next_id is null
        and s.frame_id = :spec_id
        and l.status_id != #{FRUSTRATED}
  sql

  def framed_costs
    @framed_costs ||= [0, 0].tap do |a|
      values = DB.query_first_row(FRAMED_COSTS_SQL, spec_id)
      if values
        a[0] = values[0]
        a[1] = values[1]
      end
    end
  end
end
