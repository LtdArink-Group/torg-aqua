require 'db/model'

class Delivery < Model
  module State
    SUCCESS = 'S'
    ERROR   = 'E'
  end
end
