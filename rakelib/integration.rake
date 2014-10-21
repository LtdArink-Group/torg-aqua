require 'config/airbrake'

namespace :integration do
  desc 'Airbrake test'
  task :airbrake_test do
    Airbrake.notify(Exception.new('airbrake test'))
  end

  desc 'AQUa projects update'
  task :projects do
    require 'services/projects'
    Projects.sync
  end
end
