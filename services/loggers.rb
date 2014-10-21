require 'logger'

module Loggers
  class << self
    def projects_logger
      @projects_logger ||= logger('log/projects.log')
    end

    def lots_logger
      @lots_logger ||= logger('log/lots.log')
    end

    def logger(path)
      Logger.new(path).tap do |logger|
        logger.formatter = proc do |severity, datetime, _progname, msg|
          "#{severity[0]}, [#{datetime}] #{severity} -- #{msg}\n"
        end
      end
    end
  end

  at_exit do
    Loggers.projects_logger.close
    Loggers.lots_logger.close
  end
end
