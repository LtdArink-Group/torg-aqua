require 'db/model'

class AquaLot < Model
  module State
    PENDING = 'P'
    CONSISTENT = 'C'
  end

  def initialize(plan_spec_guid, exec_spec_id)
    @plan_spec_guid = format_guid(plan_spec_guid)
    @exec_spec_id = exec_spec_id
  end

  def pending
    if exec_spec_id
      pending_with_exec_spec_id
    else
      pending_without_exec_spec_id
    end
  end

  private

  attr_reader :plan_spec_guid, :exec_spec_id

  def format_guid(guid)
    guid.bytes.map { |b| sprintf('%02X', b) }.join
  end

  def table
    self.class.table
  end

  def pending_with_exec_spec_id
    if exec_spec_id_null_count > 0
      update_pending_with_exec_spec_id
    else
      merge_pending_with_exec_spec_id
    end
  end

  def exec_spec_id_null_count
    DB.query_value(<<-sql, plan_spec_guid)
      select count(*)
        from #{table}
        where plan_spec_guid = :guid
          and exec_spec_id is null
    sql
  end

  def update_pending_with_exec_spec_id
    puts "update_pending_with_exec_spec_id #{plan_spec_guid}, #{exec_spec_id}"
    DB.exec(<<-sql, exec_spec_id, plan_spec_guid)
      update #{table}
        set exec_spec_id = :id, state = '#{State::PENDING}'
        where plan_spec_guid = hextoraw(:guid)
    sql
    DB.commit
  end

  def merge_pending_with_exec_spec_id
    puts "merge_pending_with_exec_spec_id #{plan_spec_guid}, #{exec_spec_id}"
    DB.exec(<<-sql, plan_spec_guid, exec_spec_id)
      merge into #{table} t using
      (select hextoraw(:guid) plan_spec_guid, :id exec_spec_id from dual) s
      on (t.plan_spec_guid = s.plan_spec_guid and
          t.exec_spec_id = s.exec_spec_id)
      when matched then
        update set state = '#{State::PENDING}'
      when not matched then
        insert (id, plan_spec_guid, exec_spec_id, state)
        values (#{table}_seq.nextval, s.plan_spec_guid, s.exec_spec_id,
               '#{State::PENDING}')
    sql
    DB.commit
  end

  def pending_without_exec_spec_id
    if exec_spec_id_count > 0
      update_pending_without_exec_spec_id
    else
      merge_pending_without_exec_spec_id
    end
  end

  def exec_spec_id_count
    DB.query_value(<<-sql, plan_spec_guid)
      select count(*)
        from #{table}
        where plan_spec_guid = hextoraw(:guid)
          and exec_spec_id is not null
    sql
  end

  def update_pending_without_exec_spec_id
    puts "update_pending_without_exec_spec_id #{plan_spec_guid}"
    DB.exec(<<-sql, plan_spec_guid)
      update #{table}
        set state = '#{State::PENDING}'
        where plan_spec_guid = hextoraw(:guid)
    sql
  end

  def merge_pending_without_exec_spec_id
    puts "merge_pending_without_exec_spec_id #{plan_spec_guid}"
    DB.exec(<<-sql, plan_spec_guid)
      merge into #{table} t using
      (select hextoraw(:guid) plan_spec_guid from dual) s
      on (t.plan_spec_guid = s.plan_spec_guid)
      when matched then
        update set state = '#{State::PENDING}'
      when not matched then
        insert (id, plan_spec_guid, state)
        values (#{table}_seq.nextval, s.plan_spec_guid, '#{State::PENDING}')
    sql
    DB.commit
  end
end
