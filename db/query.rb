require 'models/app_variable'

class Query
  UPDATED_AT_INDEX = 2

  attr_reader :data

  class << self
    attr_reader :descendants

    def inherited(subclass)
      if @descendants
        @descendants << subclass
      else
        @descendants = [subclass]
      end
    end
  end

  def initialize
    @data = changed_data
  end

  def save_maximum_time
    self.maximum_modified_time = data.map { |row| row[UPDATED_AT_INDEX] }.max
  end

  private

  START_YEAR = Configuration.integration.lot.start_year

  def commission_types
    Configuration.integration.lot.commission_types.join(',')
  end

  def plan_statuses
    Configuration.integration.lot.plan_statuses.join(',')
  end

  def variable_key
    @variable_key ||= 'maximum_modified_time.' +
      to_s.scan(/[A-Z][a-z]+/).map(&:downcase).join('_')
  end

  def maximum_modified_time
    if time = AppVariable.lookup(variable_key)
      Time.parse(time)
    else
      Configuration.integration.lot.start_time
    end
  end

  def maximum_modified_time=(time)
    AppVariable.merge(variable_key, time)
  end
end
