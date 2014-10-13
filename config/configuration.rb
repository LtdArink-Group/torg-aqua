require 'yaml'
require 'ostruct'

module Configuration
  class << self
    def database
      @database ||= OpenStruct.new.tap do |database|
        database.login = raw_values['database']['login']
        database.password = raw_values['database']['password']
        database.tns = raw_values['database']['tns']
      end
    end

    def integration
      @integration ||= OpenStruct.new.tap do |integration|
        integration.start_year = raw_values['integration']['start_year']
        integration.start_time = raw_values['integration']['start_time']
      end
    end

    def raw_values
      @raw_values ||= YAML.load_file('config/configuration.yml')
    end
  end
end