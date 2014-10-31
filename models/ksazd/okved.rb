require 'db/model'
require 'db/model/lookup'

class OKVED < Model
  extend Model::Lookup

  attributes :code
  schema :ksazd
  tablename :okved
end
