require 'db/query'

class PlanSpecification < Query
  CHANGED_DATA_SQL = <<-sql
    select ps.guid, null, max(ps.updated_at)
      from ksazd.protocols p,
           ksazd.commissions c,
           ksazd.plan_lots pl,
           ksazd.plan_specifications ps,
           directions d
      where p.commission_id = c.id
        and c.commission_type_id in (#{commission_types})
        and p.id = pl.protocol_id
        and pl.id = ps.plan_lot_id
        and ps.direction_id = d.ksazd_id
        --
        and pl.status_id in (#{plan_statuses})
        and pl.gkpz_year >= #{START_YEAR}
        and ps.updated_at > :max_time
      group by ps.guid
  sql

  private

  def changed_data_sql
    CHANGED_DATA_SQL
  end
end
