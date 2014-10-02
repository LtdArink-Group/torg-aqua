require 'db/model'
require 'db/model/lookup'

class CostDocument < Model
  extend Model::Lookup

  attributes :aqua_id
  id_field :ksazd_name
end
