require 'db/model'
require 'db/model/lookup'

class Subdirection < Model
  extend Model::Lookup

  attributes :aqua_name
  id_fields :ksazd_direction_id, :ksazd_subject_type_id
end
