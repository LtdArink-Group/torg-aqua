require 'db/model'

class AquaLot < Model
  module State
    PENDING = 'P'
    CONSISTENT = 'C'
  end

  attr_reader :id, :plan_spec_guid, :spec_guid, :start_time, :message

  PENDING_SQL = <<-sql
    select al.plan_spec_guid, al.spec_guid, al.id
      from #{table} al
      where al.state = '#{State::PENDING}'
  sql

  def self.pending
    DB.query_all(PENDING_SQL).map { |values| AquaLot.new(*values) }
  end

  PENDING_WITH_INFO_SQL = <<-sql
    with successfull as
      (select al.id, nvl(max(d.attempted_at), date '2000-01-01') as last_date
        from #{table} al,
             deliveries d
        where al.id = d.aqua_lot_id (+)
          and d.state (+) = 'S'
        group by al.id)
    select al.plan_spec_guid, al.spec_guid, al.id,
           min(d.attempted_at),
           max(d.message) keep (dense_rank last order by d.attempted_at)
      from #{table} al,
           deliveries d,
           successfull s
      where al.id = d.aqua_lot_id
        and al.id = s.id
        and al.state = '#{State::PENDING}'
        and d.attempted_at > s.last_date
      group by al.plan_spec_guid, al.spec_guid, al.id
  sql

  def self.pending_with_info
    DB.query_all(PENDING_WITH_INFO_SQL).map { |values| AquaLot.new(*values) }
  end

  def initialize(plan_spec_guid, spec_guid, id = nil,
                 start_time = nil, message = nil)
    @plan_spec_guid = plan_spec_guid
    @spec_guid = spec_guid
    @id = id
    @start_time = start_time
    @message = message
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
