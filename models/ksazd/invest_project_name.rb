require 'db/model'

class InvestProjectName < Model
  schema :ksazd

  def self.merge(aqua_id, name, department_id)
    DB.exec(<<-sql)
      merge into #{table} t using
      (select '#{aqua_id}' aqua_id, '#{name}' name,
              #{department_id} department_id
         from dual) s
      on (t.aqua_id = s.aqua_id)
      when matched then
        update set name = s.name, department_id = s.department_id,
                   updated_at = sysdate
      when not matched then
        insert (id, name, aqua_id, department_id, created_at, updated_at)
        values (#{table}_seq.nextval, s.name, s.aqua_id, s.department_id,
                sysdate, sysdate)
    sql
    DB.commit
  end
end
