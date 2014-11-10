require 'models/queries'
require 'models/aqua_lot'
require 'services/loggers'
require 'services/syncronizer'

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
  end
end
