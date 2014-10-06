require 'db/model'
require 'db/model/lookup'

class MonitorService < Model
  extend Model::Lookup

  attributes :aqua_id
  id_field :ksazd_id
end
