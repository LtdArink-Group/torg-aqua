require 'db/model'
require 'db/model/lookup'

class ProjectDepartment < Model
  extend Model::Lookup

  attributes :ksazd_id
  id_field :aqua_id
end
