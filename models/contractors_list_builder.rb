require 'models/ksazd/contractor'
require 'models/offer'
require 'bigdecimal'

class ContractorsListBuilder
  TYPE_RECALL     = 22002 # Тип оферты: Отзыв
  STATUS_DECLINED = 26003 # Статус оферты: Отклонена
  STATUS_WIN      = 26004 # Статус оферты: Победила

  attr_reader :contractors

  def initialize(aqua_lot)
    @aqua_lot = aqua_lot
    @contractors = Hash.new { |hash, key| hash[key] = default_contractor }
    load_plan_contractors
    load_exec_contractors if aqua_lot.exec_spec_id
  end

  private

  attr_reader :aqua_lot
  attr_writer :contractors

  def load_plan_contractors
    plan_lot_contractors.each do |contractor|
      contractors[contractor.id].tap do |c|
        c['ZNUMC1C'] = contractor.id
        c['PARTNER_NAME'] = contractor.fullname
        c['INN'] = contractor.inn
        c['KPP'] = contractor.kpp || ''
        c['PLANU'] = 'X'
      end
    end
  end

  def load_exec_contractors
    lot_offers.each do |offer|
      contractors[offer.contractor_id].tap do |c|
        c['ZNUMC1C'] = offer.contractor.id
        c['PARTNER_NAME'] = offer.contractor.fullname
        c['INN'] = offer.contractor.inn
        c['KPP'] = offer.contractor.kpp || ''
        c['PODZA'] = 'X'
        c['OTKL'] = 'X' if offer.status_id == STATUS_DECLINED
        c['ZOZ'] = 'X' if offer.type_id == TYPE_RECALL
        c['ZNPP'] = 'X' if offer.absent_auction
        c['POBED'] = 'X' if offer.status_id == STATUS_WIN
        c['ZSUM'] = format_cost(offer.cost)
        c['ZSUMWOVAT'] = format_cost(offer.cost_nds)
        c['PSUM'] = format_cost(offer.final_cost)
        c['PSUMWOVAT'] = format_cost(offer.final_cost_nds)
        c['PERETORG'] = 'true' if offer.rebidded == 1
        c['PKOL'] = offer.rebidded
      end
    end
  end

  def default_contractor
    {
      'ZNUMC1C' => '', 'PARTNER_NAME' => '', 'INN' => '', 'KPP' => '',
      'ALT_OFFER' => '', 'PLANU' => '', 'REGZP' => '', 'PODZA' => '',
      'OTKL' => '', 'ZOZ' => '', 'ZNPP' => '', 'POBED' => '',
      'ZSUM' => '0', 'ZSUMWOVAT' => '0', 'PSUM' => '0', 'PSUMWOVAT' => '0',
      'PERETORG' => 'false', 'PKOL' => 0
    }
  end

  def format_cost(cost)
    cost ? cost.to_s('F') : '0'
  end

  PLAN_LOT_CONTRACTORS_SQL = <<-sql
    select c.id, c.fullname, c.inn, c.kpp
      from ksazd.contractors c,
           ksazd.plan_lot_contractors plc
      where plc.contractor_id = c.id
        and plc.plan_lot_id = :plan_lot_id
  sql

  def plan_lot_contractors
    DB.query_all(PLAN_LOT_CONTRACTORS_SQL, aqua_lot.plan_lot_id).map do |values|
      Contractor.new.tap { |contractor| contractor.values = values }
    end
  end

  LOT_OFFERS_SQL = <<-sql
    select b.contractor_id, o.num, o.type_id, o.status_id, o.rebidded,
           o.absent_auction, s.cost, s.cost_nds, s.final_cost, s.final_cost_nds
      from ksazd.bidders b,
           ksazd.offers o,
           ksazd.offer_specifications s
      where b.id = o.bidder_id
        and o.id = s.offer_id
        and o.version = 0
        and s.specification_id = :exec_spec_id
  sql

  def lot_offers
    DB.query_all(LOT_OFFERS_SQL, aqua_lot.exec_spec_id).map do |values|
      Offer.new.tap do |offer|
        offer.values = values
        offer.contractor = Contractor.find(offer.contractor_id)
      end
    end
  end
end
