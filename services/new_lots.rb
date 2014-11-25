require 'models/queries'
require 'models/aqua_lot'
require 'models/aqua_lot_builder'
require 'models/contractors_list_builder'
require 'models/delivery'
require 'services/loggers'
require 'services/syncronizer'
require 'aqua/lots_endpoint'

class NewLots
  LAST_SYNC_TIME_KEY = 'lots.last_sync_time'
  PROCESSED = 53

  class << self
    def process
      Syncronizer.perform { new.process }
    end

    def last_sync_time
      if time = AppVariable.lookup(LAST_SYNC_TIME_KEY)
        time
      else
        Configuration.integration.lot.start_time
      end
    end
  end

  attr_reader :logger

  def initialize
    @logger = Loggers.lots_logger
  end

  def process
    detect_changes
    update_aqua
    self.last_sync_time = Time.now
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
    query.data.each { |guids| pending(guids) }
    return if query.data.empty?
    logger.info "  #{klass}: #{query.data.size}"
    query.save_maximum_time
  end

  # make frame pending too for price recalc
  def pending(guids)
    AquaLot.new(guids[0], nil).pending if guids[1]
    AquaLot.new(guids[0], guids[1]).pending
  end

  def update_aqua
    logger.info 'Передача лотов в АКВа'
    deliveries = errors = 0
    AquaLot.pending.each do |lot|
      send_lot(lot) ? deliveries += 1 : errors += 1
    end
    return if deliveries.zero? && errors.zero?
    logger.info "  Успешно: #{deliveries}, с ошибками: #{errors}"
  end

  def send_lot(lot)
    data = build_data(lot) and send_data(lot, data)
  end

  def build_data(lot)
    lot_builder = AquaLotBuilder.new(lot.plan_spec_guid, lot.spec_guid)
    return false unless data = get_lot_data(lot_builder, lot)
    contractors = ContractorsListBuilder.new(lot_builder).contractors
    data['UCH_KSDAZD_TAB'] = { 'item' => contractors.values }
    { 'I_LOTS' => { 'item' => data } }
  end

  def get_lot_data(builder, lot)
    builder.to_h
  rescue => error
    Airbrake.notify(error)
    delivery_error(lot, "КСАЗД: #{error.message}")
  end

  def send_data(lot, data)
    response = LotsEndpoint.send(data)
    if response.status == PROCESSED
      delivery_success(lot)
    else
      message = "АКВА: #{response.status} - #{response.message}"
      delivery_error(lot, message)
    end
  end

  def delivery_success(lot)
    lot.consistent
    Delivery.create(delivery_attributes(lot.id, Delivery::State::SUCCESS))
  end

  def delivery_error(lot, message)
    Delivery.create(delivery_attributes(lot.id, Delivery::State::ERROR, message))
    false
  end

  def delivery_attributes(id, state, message = '')
    { aqua_lot_id: id, state: state, attempted_at: Time.now, message: message }
  end

  def last_sync_time=(time)
    AppVariable.merge(LAST_SYNC_TIME_KEY, time)
  end
end
