require 'yaml'
require 'ostruct'

module Configuration
  class << self
    def database
      @database ||= OpenStruct.new.tap do |database|
        database.login = values['database']['login']
        database.password = values['database']['password']
        database.tns = values['database']['tns']
      end
    end

    def soap
      @soap ||= OpenStruct.new.tap do |soap|
        soap.wsdl = values['soap']['wsdl']
        soap.proxy = values['soap']['proxy']
        soap.login = values['soap']['login']
        soap.password = values['soap']['password']
      end
    end

    def integration
      @integration ||= OpenStruct.new.tap do |integration|
        integration.start_year = values['integration']['start_year']
        integration.start_time = values['integration']['start_time']
      end
    end

    def values
      @values ||= YAML.load_file('config/configuration.yml')
    end
  end
end
