require 'models/queries'
require 'models/aqua_lot'
require 'models/aqua_lot_builder'
require 'models/contractors_list_builder'
require 'models/delivery'
require 'services/loggers'
require 'services/syncronizer'
require 'aqua/lots_endpoint'

class NewLots
  PROCESSED = 53

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
    Query::Base.descendants.each { |klass| detect_changes_for(klass) }
  end

  def detect_changes_for(klass)
    query = klass.new
    query.data.each do |guids|
      AquaLot.new(*guids[0, 2]).pending
    end
    return if query.data.empty?
    logger.info "  #{klass}: #{query.data.size}"
    query.save_maximum_time
  end

  def update_aqua
    logger.info 'Передача лотов в АКВа'
    deliveries = errors = 0
    AquaLot.pending.first(10).each do |lot|
      send_lot(lot) ? deliveries += 1 : errors += 1
    end
    return if successes.zero? && errors.zero?
    logger.info "  Успешно: #{deliveries}, с ошибками: #{errors}"
  end

  def send_lot(lot)
    data = build_data(lot) and send_data(lot.id, data)
  end

  def build_data(lot)
    lot_builder = AquaLotBuilder.new(lot.plan_spec_guid, lot.exec_spec_guid)
    return flase unless data = get_lot_data(lot_builder.to_h, lot.id)
    contractors = ContractorsListBuilder.new(lot_builder).contractors
    data['UCH_KSDAZD_TAB'] = { 'item' => contractors.values }
    { 'I_LOTS' => { 'item' => data } }
  end

  def get_lot_data(builder, lot_id)
    builder.to_h
  rescue => error
    delivery_error(lot_id, "КСАЗД: #{error.message}")
  end

  def send_data(lot_id, data)
    response = LotsEndpoint.send(data)
    if response.status == PROCESSED
      delivery_success(lot_id)
    else
      message = "АКВА: #{response.status} - #{response.message}"
      delivery_error(lot_id, message)
    end
  end

  def delivery_success(lot_id)
    lot.consistent
    Delivery.create(delivery_attributes(lot_id, Delivery::State::SUCCESS))
  end

  def delivery_error(lot_id, message)
    Delivery.create(delivery_attributes(lot_id, Delivery::State::ERROR, message))
    false
  end

  def delivery_attributes(id, state, message = '')
    { aqua_lot_id: id, state: state, attempted_at: Time.now, message: message }
  end
end
