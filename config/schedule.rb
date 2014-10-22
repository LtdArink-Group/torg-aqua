job_type :runner, 'cd :path && nice -19 bundle exec rake :task --silent :output'

every 1.day, :at => '7:30 am' do
  rake 'integration:projects'
end
