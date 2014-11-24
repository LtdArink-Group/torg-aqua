require 'db/model'
require 'db/model/lookup'

class Department < Model
  extend Model::Lookup

  attributes :aqua_id
  id_field :ksazd_id

  ROOT_SQL = <<-sql
    select id
      from
        (select t.id, t.parent_dept_id
          from ksazd.departments t
          connect by prior t.parent_dept_id = t.id
          start with t.id = :id)
      where parent_dept_id is null
  sql

  def self.root(ksazd_id)
    DB.query_value(ROOT_SQL, ksazd_id)
  end
end
