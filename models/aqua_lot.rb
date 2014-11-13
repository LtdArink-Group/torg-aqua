require 'db/model'

class AquaLot < Model
  module State
    PENDING = 'P'
    CONSISTENT = 'C'
  end

  PENDING_SQL = <<-sql
    select al.plan_spec_guid, al.exec_spec_guid
      from #{table} al
      where al.state = '#{State::PENDING}'
  sql

  def self.pending
    DB.query_all(PENDING_SQL)
  end

  def initialize(plan_spec_guid, exec_spec_guid)
    @plan_spec_guid = DB.guid(plan_spec_guid)
    @exec_spec_guid = DB.guid(exec_spec_guid)
  end

  def pending
    if exec_spec_guid
      pending_with_exec_spec_id
    else
      pending_without_exec_spec_id
    end
  end

  private

  attr_reader :plan_spec_guid, :exec_spec_guid

  PENDING_WITH_EXEC_SPEC_ID_SQL = <<-sql
    merge into #{table} t using
    (select hextoraw(:guid1) plan_spec_guid,
            hextoraw(:guid2) exec_spec_guid
       from dual) s
    on (t.plan_spec_guid = s.plan_spec_guid and
        t.exec_spec_guid = s.exec_spec_guid)
    when matched then
      update set state = '#{State::PENDING}'
    when not matched then
      insert (id, plan_spec_guid, exec_spec_guid, state)
      values (#{table}_seq.nextval, s.plan_spec_guid,
              s.exec_spec_guid, '#{State::PENDING}')
  sql

  def pending_with_exec_spec_id
    DB.exec(PENDING_WITH_EXEC_SPEC_ID_SQL, plan_spec_guid, exec_spec_guid)
    DB.commit
  end

  PENDING_WITHOUT_EXEC_SPEC_ID_SQL = <<-sql
    merge into #{table} t using
    (select hextoraw(:guid) plan_spec_guid from dual) s
    on (t.plan_spec_guid = s.plan_spec_guid and t.exec_spec_guid is null)
    when matched then
      update set state = '#{State::PENDING}'
    when not matched then
      insert (id, plan_spec_guid, state)
      values (#{table}_seq.nextval, s.plan_spec_guid, '#{State::PENDING}')
  sql

  def pending_without_exec_spec_id
    DB.exec(PENDING_WITHOUT_EXEC_SPEC_ID_SQL, plan_spec_guid)
    DB.commit
  end
end
