require 'db/model'

class AquaLot < Model
  module State
    PENDING = 'P'
    CONSISTENT = 'C'
  end

  def initialize(plan_spec_guid, exec_spec_guid)
    @plan_spec_guid = format_guid(plan_spec_guid)
    @exec_spec_guid = format_guid(exec_spec_guid)
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

  def format_guid(guid)
    guid.bytes.map { |b| sprintf('%02X', b) }.join if guid
  end

  def table
    self.class.table
  end

  def pending_with_exec_spec_id
    DB.exec(<<-sql, plan_spec_guid, exec_spec_guid)
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
    DB.commit
  end

  def pending_without_exec_spec_id
    DB.exec(<<-sql, plan_spec_guid)
      merge into #{table} t using
      (select hextoraw(:guid) plan_spec_guid from dual) s
      on (t.plan_spec_guid = s.plan_spec_guid and t.exec_spec_guid is null)
      when matched then
        update set state = '#{State::PENDING}'
      when not matched then
        insert (id, plan_spec_guid, state)
        values (#{table}_seq.nextval, s.plan_spec_guid, '#{State::PENDING}')
    sql
    DB.commit
  end
end
