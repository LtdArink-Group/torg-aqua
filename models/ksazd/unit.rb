require 'db/model'
require 'db/model/lookup'

class Unit < Model
  extend Model::Lookup

  attributes :code
  schema :ksazd
end
