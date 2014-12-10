require 'db/model'

class AquaLot < Model
  module State
    PENDING = 'P'
    CONSISTENT = 'C'
  end

  attr_reader :id, :plan_spec_guid, :spec_guid, :start_time, :message,
              :gkpz_year, :department, :direction, :lot_num, :spec_name,
              :tender_id

  PENDING_SQL = <<-sql
    select al.plan_spec_guid, al.spec_guid, al.id
      from #{table} al
      where al.state = '#{State::PENDING}'
  sql

  def self.pending
    DB.query_all(PENDING_SQL).map { |values| AquaLot.new(*values) }
  end

  def self.commission_types
    Configuration.integration.lot.commission_types.join(',')
  end

  def self.plan_statuses
    Configuration.integration.lot.plan_statuses.join(',')
  end

  PENDING_WITH_INFO_SQL = <<-sql
    with
      successfull as
      (select al.id, nvl(max(d.attempted_at), date '2000-01-01') as last_date
        from #{table} al,
             deliveries d
        where al.id = d.aqua_lot_id (+)
          and d.state (+) = 'S'
        group by al.id),
      plan_lot_info as
      (select ps.guid,
              max(pl.gkpz_year) keep (dense_rank first order by pl.version) gkpz_year,
              max(d.name) keep (dense_rank first order by pl.version) department,
              max(dir.name) keep (dense_rank first order by pl.version) direction,
              max(to_char(pl.num_tender) || '.' || to_char(pl.num_lot)) keep (dense_rank first order by pl.version) lot_num,
              max(ps.name) keep (dense_rank first order by pl.version) spec_name
        from ksazd.protocols p,
             ksazd.commissions c,
             ksazd.plan_lots pl,
             ksazd.plan_specifications ps,
             ksazd.departments d,
             ksazd.dictionaries dir
        where p.commission_id = c.id
          and p.id = pl.protocol_id
          and pl.id = ps.plan_lot_id
          and ps.customer_id = d.id
          and ps.direction_id = dir.ref_id
          --
          and c.commission_type_id in (#{commission_types})
          and pl.status_id in (#{plan_statuses})
        group by ps.guid),
      tender as
      (select s.guid, max(l.tender_id) tender_id
        from ksazd.lots l,
             ksazd.specifications s
        where l.id = s.lot_id
          and l.next_id is null
        group by s.guid)
    select al.plan_spec_guid, al.spec_guid, al.id,
           min(d.attempted_at),
           max(d.message) keep (dense_rank last order by d.attempted_at),
           max(to_char(pli.gkpz_year)),
           max(pli.department),
           max(pli.direction),
           max(pli.lot_num),
           max(pli.spec_name),
           max(t.tender_id)
      from #{table} al,
           deliveries d,
           successfull s,
           plan_lot_info pli,
           tender t
      where al.id = d.aqua_lot_id
        and al.id = s.id
        and al.plan_spec_guid = pli.guid
        and al.spec_guid = t.guid (+)
        --
        and al.state = '#{State::PENDING}'
        and d.attempted_at > s.last_date
      group by al.plan_spec_guid, al.spec_guid, al.id
  sql

  def self.pending_with_info
    DB.query_all(PENDING_WITH_INFO_SQL).map { |values| AquaLot.new(*values) }
  end

  def initialize(plan_spec_guid, spec_guid, id = nil, start_time = nil,
                 message = nil, gkpz_year = nil, department = nil,
                 direction = nil, lot_num = nil, spec_name = nil,
                 tender_id = nil)
    @plan_spec_guid = plan_spec_guid
    @spec_guid = spec_guid
    @id = id
    @start_time = start_time
    @message = message
    @gkpz_year = gkpz_year
    @department = department
    @direction = direction
    @lot_num = lot_num
    @spec_name = spec_name
    @tender_id = tender_id
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
