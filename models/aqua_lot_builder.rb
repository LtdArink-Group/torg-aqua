require 'models/ksazd'
require 'models/mapping'
require 'bigdecimal'
require 'base64'

class AquaLotBuilder
  ZERO = BigDecimal.new('0')
  # ИС КСАЗД
  SOLUTION_TYPE_EI = 40_002 # Заключить договор с единственным поставщиком
  CONTRACT_DONE    = 33_100 # Договор заключен
  FRUSTRATED       = 33_110 # Признана несостоявшейся
  STATE_PLANNED    = 1     # План (не Внеплан)
  ADDITIONAL_RATIO = 0.2   # Дозакупка >< 20%
  CANCELLED        = 15_004 # Отменен
  EXCLUDED         = 15_007 # Исключен СД
  TENDER_TYPE_ZZC  = 10_014 # Закрытый запрос цен
  TENDER_TYPE_ORK  = 10_018 # Открытый рамочный конкурс
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
    @spec_deleted = false
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
      'SPP' => invest_project,
      # Название лота
      'LNAME' => truncate(plan_spec.name, 360),
      # Номер лота
      'LNUM' => format('%d.%d', plan_lot.num_tender, plan_lot.num_lot),
      # Закупка плановая/внеплановая (+ дозакупка)
      'LPLVP' => plan_lot.additional_to ? additional_state : lot_state,
      # Статус лота
      'LOTSTATUS' => lotstatus,
      # метка удаления
      'LOTDEL' => lotdel,
      # Организатор процедуры
      'ORG' => Organizer.lookup(plan_lot.department_id) || AQUA_DZO,
      # Закупочная комиссия
      'ZK' => comission,
      # Способ закупки (план)
      'SPZKP' => TenderType.lookup(plan_lot.tender_type_id),
      # Способ закупки (по способу объявления)
      'SPZKF' => TenderType.lookup(tender.tender_type_id) || '',
      # Способ закупки (ЕИ по итогам конкурентных процедур)
      'SPZEI' => winner_protocol_lot.solution_type_id == SOLUTION_TYPE_EI ? AQUA_EI : '',
      # Планируемая цена лота (руб. с НДС)
      'SUMN' => format_cost(cost_nds * qty),
      # Планируемая цена лота (руб. без  НДС)
      'SUM_' => format_cost(cost * qty),
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
      'B2BF' => EtpAddress.lookup(tender.etp_address_id) || '',
      # Подразделение - куратор закупки
      'ZKURATOR' => zkurator,
      # Дата начала поставки товаров, выполнения работ, услуг
      'DATENP' => format_date(plan_spec.delivery_date_begin),
      # Дата окончания поставки товаров, выполнения работ, услуг
      'DATEOP' => format_date(plan_spec.delivery_date_end),
      # Куратор
      'KURATOR' => truncate(plan_spec.curator, 60),
      # Технический куратор
      'TKURATOR' => truncate(plan_spec.tech_curator, 60),
      # Подраздел ГКПЗ
      'L_FUNBUD' => Subdirection.lookup(plan_spec.direction_id,
                                        plan_lot.subject_type_id),
      # Обоснование (в случае ЕИ или отклонения от регламентных порогов)
      'P_REASON' => truncate(plan_lot.tender_type_explanations, 1000) || '',
      # Обоснование (документ)
      'P_REASON_DOC' => p_reason_doc,
      # Пункт положения
      'P_PARAGRAPH' => paragraph,
      # Количество
      'ZEI' => qty,
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
      'PRN1' => truncate(prn1, 500),
      # Причины невыполнения срока заключения договора
      'PRN2' => truncate(prn2, 500),
      # Код валюты
      'L_WAERS' => RUSSIAN_RUBLE,
      # Номер процедуры на ЭТП
      'ZNUMPR' => etp_num || '',
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

  private

  # hash values -----------------------------------------------------

  def customer
    ksazd_id = plan_spec.customer_id
    root_id = Department.root(ksazd_id)
    Department.lookup(root_id) || fail("Не удалось найти заказчика АКВА для id #{ksazd_id}")
  end

  def invest_project
    invest_project_name_id =
      InvestProject.find(plan_spec.invest_project_id).invest_project_name_id
    InvestProjectName.lookup(invest_project_name_id) ||
      fail("Не удалось найти проект АКВА для id #{plan_spec.invest_project_id}")
  end

  def lotstatus
    case lot.status_id
    when FRUSTRATED then TENDER_FRUSTRATED
    when CONTRACT_DONE then TENDER_COMPLETED
    else IN_PROGRESS
    end
  end

  def lotdel
    if spec_deleted?
      'X'
    else
      [CANCELLED, EXCLUDED].include?(plan_lot.status_id) ? 'X' : ''
    end
  end

  def comission
    return '' unless plan_lot.commission_id
    type_id = Commission.find(plan_lot.commission_id).commission_type_id
    CommissionType.lookup(type_id)
  end

  def cost_nds
    spec_guid && spec_id ? spec_cost_nds : plan_spec_cost_nds
  end

  def cost
    spec_guid && spec_id ? spec_cost : plan_spec_cost
  end

  def zkurator
    ksazd_id = plan_spec.monitor_service_id
    value = MonitorService.lookup(ksazd_id) || fail("Не удалось найти подразделение-куратор АКВА для id #{ksazd_id}")
    sprintf('%03d', value)
  end

  def p_reason_doc
    (doc = plan_lot.explanations_doc) ? doc.slice(0, 120) : ''
  end

  def paragraph
    return '' if plan_lot.point_clause.nil?
    result = plan_lot.point_clause.scan(/5\.9\.1\.([1-5])/)
    result.any? ? "00#{result[0][0]}" : ''
  end

  def qty
    spec_guid && spec_id ? spec.qty : plan_spec.qty
  end

  def prn1
    [].tap do |a|
      a << lot.non_public_reason.read if lot.non_public_reason
      a << Protocol.find(plan_lot.protocol_id).details if plan_lot.protocol_id
    end.join ' / '
  end

  def prn2
    lot.non_contract_reason ? lot.non_contract_reason.read : ''
  end

  def etp_num
    fail 'Номер процедуры на ЭТП больше 8-и символов' if tender.etp_num && tender.etp_num > 99_999_999
    tender.etp_num
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

  def winner_protocol_lot
    return NullWinnerProtocolLot.new unless spec_id
    WinnerProtocolLot.find(lot.winner_protocol_id, lot.id) || NullWinnerProtocolLot.new
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
      a[0] = [cost_nds, cost, cost_nds] if fix_amounts?
      (1..5).each { |i| a[i] = Array.new(3, ZERO) } if fix_zzc?
    end
  end

  def spec_deleted?
    spec_id # need to check for deleted specs
    @spec_deleted
  end

  def spec_cost_nds
    spec.cost_nds.tap do |cost|
      fail 'Цена лота с НДС равна нулю.' if cost == 0
    end
  end

  def spec_cost
    spec.cost.tap do |cost|
      fail 'Цена лота без НДС равна нулю.' if cost == 0
      fail 'Цена лота без НДС больше цены лота с НДС.' if cost > spec.cost_nds
      if spec.cost_nds / cost > 2
        fail 'Цена лота без НДС меньше цены лота с НДС более чем в два раза.'
      end
    end
  end

  def plan_spec_cost_nds
    plan_spec.cost_nds.tap do |cost|
      fail 'Плановая цена лота с НДС равна нулю.' if cost == 0
    end
  end

  def plan_spec_cost
    plan_spec.cost.tap do |cost|
      fail 'Плановая цена лота без НДС равна нулю.' if cost == 0
      if cost > plan_spec.cost_nds
        fail 'Плановая цена лота без НДС больше плановой цены лота с НДС.'
      end
      if plan_spec.cost_nds / cost > 2
        fail 'Плановая цена лота без НДС меньше плановой цены лота с НДС более чем в два раза.'
      end
    end
  end

  def fix_amounts?
    [TENDER_TYPE_ZZC].include? tender.tender_type_id
  end

  def fix_zzc?
    tender.tender_type_id == TENDER_TYPE_ZZC
  end

  def format_date(time)
    time ? time.getlocal.to_date : ''
  end

  def format_guid(guid)
    guid ? Base64.encode64(guid).chop : ''
  end

  def format_cost(cost)
    cost.to_s('F')
  end

  def truncate(string, length)
    string[0..(length - 1)] if string
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

  PLAN_SPEC_SQL = <<-SQL
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
  SQL

  def plan_spec_id
    @plan_spec_id ||= DB.query_value(PLAN_SPEC_SQL, DB.guid(plan_spec_guid)).to_i
  end

  SPEC_ID_FROM_PLAN_SQL = <<-SQL
    select max(s.id)
      from ksazd.specifications s
        inner join ksazd.lots l on (s.lot_id = l.id and l.next_id is null)
        inner join ksazd.plan_specifications ps on (ps.id = s.plan_specification_id)
      where ps.guid = hextoraw(:guid)
      having max(s.id) is not null
  SQL

  SPEC_ID_SQL = <<-SQL
    select s.id
      from ksazd.specifications s,
           ksazd.lots l
      where s.lot_id = l.id
        and l.next_id is null
        and s.guid = hextoraw(:guid)
  SQL

  def spec_id
    @spec_id ||=
      if spec_guid
        begin
          DB.query_value(SPEC_ID_SQL, DB.guid(spec_guid)).to_i
        rescue NoMethodError
          @spec_deleted = true
          nil
        end
      else
        values = DB.query_first_row(SPEC_ID_FROM_PLAN_SQL, DB.guid(plan_spec_guid))
        values[0].to_i if values
      end
  end

  MAIN_LOT_COST_SQL = <<-SQL
    select sum(s.cost_nds * s.qty)
      from ksazd.plan_specifications s,
           ksazd.plan_lots l
      where s.plan_lot_id = l.id
        and l.guid = hextoraw(:guid)
        and l.version = 0
  SQL

  def main_lot_cost
    DB.query_value(MAIN_LOT_COST_SQL, DB.guid(plan_lot.additional_to))
  end

  ADDITIONAL_COST_SUM_SQL = <<-SQL
    select sum(s.cost_nds * s.qty)
      from ksazd.plan_specifications s,
           ksazd.plan_lots l
      where s.plan_lot_id = l.id
        and l.additional_to = hextoraw(:guid)
        and l.additional_num <= :num
        and l.version = 0
  SQL

  def additional_cost_sum
    DB.query_value(ADDITIONAL_COST_SUM_SQL, DB.guid(plan_lot.additional_to),
                   plan_lot.additional_num)
  end

  ADDITIONAL_TO_SQL = <<-SQL
    select distinct s.guid
      from ksazd.plan_specifications s,
           ksazd.plan_lots l
      where s.plan_lot_id = l.id
        and s.direction_id = :direction_id
        and l.guid = hextoraw(:guid)
  SQL

  def additional_to
    return '' unless plan_lot.additional_to
    guid = DB.guid(plan_lot.additional_to)
    DB.query_value(ADDITIONAL_TO_SQL, plan_spec.direction_id, guid)
  end

  OKATO_SQL = <<-SQL
    select nvl(h.okato, a.okato)
      from ksazd.fias_plan_specifications s,
           ksazd.fias_houses h,
           ksazd.fias_addrs a
      where s.houseid = h.houseid(+)
        and s.addr_aoid = a.aoid
        and s.plan_specification_id = :id
  SQL

  def okato
    DB.query_value(OKATO_SQL, plan_spec_id)
  rescue NoMethodError
    raise 'Не указаны адреса поставки'
  end

  PLAN_SPEC_AMOUNTS_SQL = <<-SQL
    select nvl(a.amount_finance_nds, 0),
           nvl(a.amount_mastery, 0),
           nvl(a.amount_mastery_nds, 0)
      from ksazd.plan_spec_amounts a
      where a.plan_specification_id = :id
      order by a.year
  SQL

  def plan_spec_amounts_from_db
    DB.query_all(PLAN_SPEC_AMOUNTS_SQL, plan_spec_id)
  end

  def framed_cost_nds
    framed_costs[0] || 0
  end

  def framed_cost
    framed_costs[1] || 0
  end

  FRAMED_COSTS_SQL = <<-SQL
    select sum(s.cost_nds), sum(s.cost)
      from ksazd.specifications s,
           ksazd.lots l
      where s.lot_id = l.id
        and l.next_id is null
        and s.frame_id = :spec_id
        and l.status_id != #{FRUSTRATED}
  SQL

  def framed_costs
    @framed_costs ||= if spec_id
                        DB.query_first_row(FRAMED_COSTS_SQL, spec_id)
                      else
                        Array.new(2)
                      end
  end
end
