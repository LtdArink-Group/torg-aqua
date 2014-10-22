require 'airbrake'

Airbrake.configure do |config|
  config.api_key = '65466ed2d7e61a67ffdc7b746217fdba'
  config.host    = '172.30.47.193'
  config.port    = 666
  config.secure  = config.port == 443
end
