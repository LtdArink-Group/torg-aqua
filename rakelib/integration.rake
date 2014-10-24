require 'config/airbrake'

namespace :integration do
  desc 'Corn test'
  task :cron_test do
    require 'services/loggers'
    Loggers.projects_logger.info 'cron test'
  end

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
