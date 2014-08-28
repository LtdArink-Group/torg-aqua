task default: %w[test]

desc "Run specs"
task :test do
  sh 'rspec spec'
end

desc "Intergation iteration"
task :integration do
  require './models/user'
  p "Users in db: #{User.count}"
end
