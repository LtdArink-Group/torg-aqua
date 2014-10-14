require 'models/ksazd/contractor'
require 'models/offer'
require 'bigdecimal'

class ContractorsListBuilder
  TYPE_RECALL     = 22002 # Тип оферты: Отзыв
  STATUS_DECLINED = 26003 # Статус оферты: Отклонена
  STATUS_WIN      = 26004 # Статус оферты: Победила
  ZERO            = BigDecimal.new('0')

  attr_reader :contractors

  def initialize(aqua_lot)
    @aqua_lot = aqua_lot
    @contractors = Hash.new { |hash, key| hash[key] = default_contractor }
    load_plan_contractors
    load_exec_contractors
  end

  private

  attr_reader :aqua_lot

  attr_writer :contractors

  def load_plan_contractors
    plan_lot_contractors.each do |contractor|
      contractors[contractor.id].tap do |c|
        c['ZNUMKSAZD'] = contractor.id
        c['PARTNER_NAME'] = contractor.fullname
        c['INN'] = contractor.inn
        c['KPP'] = contractor.kpp
        c['PLANU'] = 'X'
      end
    end
  end

  def load_exec_contractors
    lot_offers.each do |offer|
      contractors[offer.contractor_id].tap do |c|
        c['ZNUMKSAZD'] = offer.contractor.id
        c['PARTNER_NAME'] = offer.contractor.fullname
        c['INN'] = offer.contractor.inn
        c['KPP'] = offer.contractor.kpp
        c['PODZA'] = 'X'
        c['OTKL'] = 'X' if offer.status_id == STATUS_DECLINED
        c['ZOZ'] = 'X' if offer.type_id == TYPE_RECALL
        c['ZNPP'] = 'X' if offer.absent_auction
        c['POBED'] = 'X' if offer.status_id == STATUS_WIN
        c['ZSUM'] = offer.cost || ZERO
        c['ZSUMWOVAT'] = offer.cost_nds || ZERO
        c['PSUM'] = offer.final_cost || ZERO
        c['PSUMWOVAT'] = offer.final_cost_nds || ZERO
        c['PERETORG'] = 'true' if offer.rebidded == 1
        c['PKOL'] = offer.rebidded
      end
    end
  end

  def default_contractor
    {
      'ZNUMKSAZD' => nil, 'PARTNER_NAME' => nil, 'INN' => nil, 'KPP' => nil,
      'ALT_OFFER' => nil, 'PLANU' => nil, 'REGZP' => nil, 'PODZA' => nil,
      'OTKL' => nil, 'ZOZ' => nil, 'ZNPP' => nil, 'POBED' => nil,
      'ZSUM' => ZERO, 'ZSUMWOVAT' => ZERO, 'PSUM' => ZERO, 'PSUMWOVAT' => ZERO,
      'PERETORG' => 'false', 'PKOL' => 0
    }
  end

  def plan_lot_contractors
    DB.query_all(<<-sql)
      select c.id, c.fullname, c.inn, c.kpp
        from ksazd.contractors c,
             ksazd.plan_lot_contractors plc
        where plc.contractor_id = c.id
          and plc.plan_lot_id = #{aqua_lot.plan_lot_id}
    sql
      .map do |values|
        Contractor.new.tap { |contractor| contractor.values = values }
      end
  end

  def lot_offers
    DB.query_all(<<-sql)
      select b.contractor_id, o.num, o.type_id, o.status_id, o.rebidded,
             o.absent_auction, s.cost, s.cost_nds, s.final_cost, s.final_cost_nds
        from ksazd.bidders b,
             ksazd.offers o,
             ksazd.offer_specifications s
        where b.id = o.bidder_id
          and o.id = s.offer_id
          and o.version = 0
          and s.specification_id = #{aqua_lot.exec_spec_id}
    sql
      .map do |values|
        Offer.new.tap do |offer|
          offer.values = values
          offer.contractor = Contractor.find(offer.contractor_id)
        end
      end
  end
end