require 'yaml'
require 'ostruct'
require 'logger'

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
        soap.proxy = values['soap']['proxy']
        soap.lot = lot
        soap.project = project
      end
    end

    def lot
      OpenStruct.new.tap do |lot|
        lot.wsdl = values['soap']['lot']['wsdl']
        lot.login = values['soap']['lot']['login']
        lot.password = values['soap']['lot']['password']
      end
    end

    def project
      OpenStruct.new.tap do |project|
        project.wsdl = values['soap']['project']['wsdl']
        project.login = values['soap']['project']['login']
        project.password = values['soap']['project']['password']
        project.system = values['soap']['project']['system']
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

    def projects_logger
      @projects_logger ||= Logger.new('log/projects.log')
    end

    def lots_logger
      @lots_logger ||= Logger.new('log/lots.log')
    end
  end

  at_exit do
    Configuration.projects_logger.close
    Configuration.lots_logger.close
  end
end
