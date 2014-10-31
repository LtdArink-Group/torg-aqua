require 'db/model'
require 'db/model/lookup'

class OKDP < Model
  extend Model::Lookup

  attributes :code
  schema :ksazd
  tablename :okdp
end
