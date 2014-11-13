require 'models/queries'
require 'models/aqua_lot'
require 'models/aqua_lot_builder'
require 'models/contractors_list_builder'
require 'services/loggers'
require 'services/syncronizer'
require 'aqua/lots_endpoint'

class NewLots
  def self.process
    Syncronizer.perform { new.process }
  end

  attr_reader :logger

  def initialize
    @logger = Loggers.lots_logger
  end

  def process
    detect_changes
    update_aqua
  rescue Exception => e
    logger.fatal "#{e.class}. #{e.message}\n#{e.backtrace.join("\n")}"
    Airbrake.notify(e)
    raise e
  end

  private

  def detect_changes
    logger.info 'Обнаружение изменившихся данных'
    Query.descendants.each { |klass| detect_changes_for(klass) }
  end

  def detect_changes_for(klass)
    query = klass.new
    query.data.each do |lot|
      AquaLot.new(*lot[0, 2]).pending
    end
    return if query.data.empty?
    logger.info "  #{klass}: #{query.data.size}"
    query.save_maximum_time
  end

  def update_aqua
    logger.info 'Передача лотов в АКВа'
    AquaLot.pending.first(10).each do |lot|
      send_lot(lot)
    end
  end

  def send_lot
    lot_builder = AquaLotBuilder.new(PLAN_SPEC_GUID, nil)
    data = lot_builder.to_h
    contractors = ContractorsListBuilder.new(lot_builder).contractors
    data['UCH_KSDAZD_TAB'] = { 'item' => contractors.values }
    response = LotsEndpoint.send('I_LOTS' => { 'item' => data })
    puts "response status: #{response.status}"
    puts response.message if response.message
  end
end
