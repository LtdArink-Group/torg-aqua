require 'config/airbrake'

namespace :integration do
  desc 'AQUa projects update'
  task :projects do
    require 'services/projects'
    Projects.sync
  end

  desc 'AQUa lots export'
  task :lots do
    require 'services/loggers'
    Loggers.lots_logger.info 'lots cron test'
  end
end
