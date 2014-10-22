require 'config/airbrake'

namespace :integration do
  desc 'AQUa projects update'
  task :projects do
    require 'services/projects'
    Projects.sync
  end
end
