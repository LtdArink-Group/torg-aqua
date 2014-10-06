require 'db/model'
require 'db/model/lookup'

class Direction < Model
  extend Model::Lookup

  attributes :aqua_name
  id_field :ksazd_id
end
