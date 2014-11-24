require 'db/model'

class AquaLot < Model
  module State
    PENDING = 'P'
    CONSISTENT = 'C'
  end

  attr_accessor :id
  attr_reader :plan_spec_guid, :spec_guid

  PENDING_SQL = <<-sql
    select al.id, al.plan_spec_guid, al.spec_guid
      from #{table} al
      where al.state = '#{State::PENDING}'
  sql

  def self.pending
    DB.query_all(PENDING_SQL).map do |values|
      AquaLot.new(values[1], values[2]).tap { |lot| lot.id = values[0] }
    end
  end

  def initialize(plan_spec_guid = nil, spec_guid = nil)
    @plan_spec_guid = plan_spec_guid
    @spec_guid = spec_guid
  end

  def pending
    state(State::PENDING)
  end

  def consistent
    state(State::CONSISTENT)
  end

  private

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
    DB.exec(MERGE_ZZC_SQL, DB.guid(plan_spec_guid), DB.guid(spec_guid), state, state)
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
    DB.exec(MERGE_SQL, DB.guid(plan_spec_guid), state, state)
    DB.commit
  end
end
