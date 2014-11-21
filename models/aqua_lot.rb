require 'db/model'

class AquaLot < Model
  module State
    PENDING = 'P'
    CONSISTENT = 'C'
  end

  attributes :id, :plan_spec_guid, :spec_guid

  PENDING_SQL = <<-sql
    select al.plan_spec_guid, al.spec_guid
      from #{table} al
      where al.state = '#{State::PENDING}'
  sql

  def self.pending
    DB.query_all(PENDING_SQL).map do |values|
      AquaLot.new.tap { |lot| lot.values = values }
    end
  end

  def initialize(plan_spec_guid, spec_guid)
    @plan_spec_guid = DB.guid(plan_spec_guid)
    @spec_guid = DB.guid(spec_guid)
  end

  def pending
    state(State::PENDING)
  end

  def consistent
    state(State::CONSISTENT)
  end

  private

  attr_reader :plan_spec_guid, :spec_guid

  def table
    self.class.table
  end

  def state(state)
    if spec_guid
      merge_zzc(state)
    else
      merge(state)
    end
  end

  MERGE_ZZC_SQL = <<-sql
    merge into #{table} t using
    (select hextoraw(:guid1) plan_spec_guid,
            hextoraw(:guid2) spec_guid
       from dual) s
    on (t.plan_spec_guid = s.plan_spec_guid and
        t.spec_guid = s.spec_guid)
    when matched then
      update set state = :state
    when not matched then
      insert (id, plan_spec_guid, spec_guid, state)
      values (#{table}_seq.nextval, s.plan_spec_guid,
              s.spec_guid, :state)
  sql

  def merge_zzc(state)
    DB.exec(MERGE_ZZC_SQL, plan_spec_guid, spec_guid, state)
    DB.commit
  end

  MERGE_SQL = <<-sql
    merge into #{table} t using
    (select hextoraw(:guid) plan_spec_guid from dual) s
    on (t.plan_spec_guid = s.plan_spec_guid and t.spec_guid is null)
    when matched then
      update set state = :state
    when not matched then
      insert (id, plan_spec_guid, state)
      values (#{table}_seq.nextval, s.plan_spec_guid, :state)
  sql

  def merge(state)
    DB.exec(MERGE_SQL, plan_spec_guid, state)
    DB.commit
  end
end
