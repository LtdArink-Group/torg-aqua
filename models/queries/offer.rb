require 'db/query'

class Offer < Query
  CHANGED_DATA_SQL = <<-sql
    select ps.guid, null, max(o.updated_at)
      from ksazd.protocols p,
           ksazd.commissions c,
           ksazd.plan_lots pl,
           ksazd.plan_specifications ps,
           directions d,
           --
           ksazd.specifications s,
           ksazd.lots l,
           ksazd.offers o
      where p.commission_id = c.id
        and c.commission_type_id in (#{commission_types})
        and p.id = pl.protocol_id
        and pl.id = ps.plan_lot_id
        and ps.direction_id = d.ksazd_id
        --
        and ps.id = s.plan_specification_id
        and s.lot_id = l.id
        and l.id = o.lot_id
        --
        and pl.status_id in (#{plan_statuses})
        and pl.gkpz_year >= #{START_YEAR}
        and o.updated_at > :max_time
      group by ps.guid
  sql

  private

  def changed_data_sql
    CHANGED_DATA_SQL
  end
end