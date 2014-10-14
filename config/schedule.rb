job_type :runner, 'cd :path && nice -19 bundle exec rake :task --silent :output'

every 1.hour do
  runner 'test'
end
