require 'db/model'
require 'db/model/lookup'

class AppVariable < Model
  extend Model::Lookup

  attributes :value
  id_fields :key

  def self.merge(key, value)
    DB.exec(<<-sql)
      merge into #{table} t using
      (select '#{key}' key, '#{value}' value from dual) s
      on (t.key = s.key)
      when matched then
        update set value = s.value
      when not matched then
        insert (key, value)
        values (s.key, s.value)
    sql
    DB.commit
  end
end
