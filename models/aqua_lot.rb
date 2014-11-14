require 'db/model'

class AquaLot < Model
  module State
    PENDING = 'P'
    CONSISTENT = 'C'
  end

  attributes :id, :plan_spec_guid, :exec_spec_guid

  PENDING_SQL = <<-sql
    select al.plan_spec_guid, al.exec_spec_guid
      from #{table} al
      where al.state = '#{State::PENDING}'
  sql

  def self.pending
    DB.query_all(PENDING_SQL).map do |values|
      AquaLot.new.tap { |lot| lot.values = values }
    end
  end

  def initialize(plan_spec_guid, exec_spec_guid)
    @plan_spec_guid = DB.guid(plan_spec_guid)
    @exec_spec_guid = DB.guid(exec_spec_guid)
  end

  def pending
    state(State::PENDING)
  end

  def consistent
    state(State::CONSISTENT)
  end

  private

  attr_reader :plan_spec_guid, :exec_spec_guid

  def table
    self.class.table
  end

  def state(state)
    if exec_spec_guid
      merge_with_exec_spec_id(state)
    else
      merge_without_exec_spec_id(state)
    end
  end

  MERGE_WITH_EXEC_SPEC_ID_SQL = <<-sql
    merge into #{table} t using
    (select hextoraw(:guid1) plan_spec_guid,
            hextoraw(:guid2) exec_spec_guid
       from dual) s
    on (t.plan_spec_guid = s.plan_spec_guid and
        t.exec_spec_guid = s.exec_spec_guid)
    when matched then
      update set state = :state
    when not matched then
      insert (id, plan_spec_guid, exec_spec_guid, state)
      values (#{table}_seq.nextval, s.plan_spec_guid,
              s.exec_spec_guid, :state)
  sql

  def merge_with_exec_spec_id(state)
    DB.exec(MERGE_WITH_EXEC_SPEC_ID_SQL, plan_spec_guid, exec_spec_guid, state)
    DB.commit
  end

  MERGE_WITHOUT_EXEC_SPEC_ID_SQL = <<-sql
    merge into #{table} t using
    (select hextoraw(:guid) plan_spec_guid from dual) s
    on (t.plan_spec_guid = s.plan_spec_guid and t.exec_spec_guid is null)
    when matched then
      update set state = :state
    when not matched then
      insert (id, plan_spec_guid, state)
      values (#{table}_seq.nextval, s.plan_spec_guid, :state)
  sql

  def merge_without_exec_spec_id(state)
    DB.exec(MERGE_WITHOUT_EXEC_SPEC_ID_SQL, plan_spec_guid, state)
    DB.commit
  end
end
