require 'db/query'

class Query::WinnerProtocolLot < Query::Base
  CHANGED_DATA_SQL = <<-SQL
    select
      ps.guid, null, max(wp.updated_at)
    from ksazd.protocols p
      inner join ksazd.commissions c on (p.commission_id = c.id and c.commission_type_id in (#{commission_types}))
      inner join ksazd.plan_lots pl on (p.id = pl.protocol_id)
      inner join ksazd.plan_specifications ps on (pl.id = ps.plan_lot_id)
      inner join directions d on (ps.direction_id = d.ksazd_id)
      inner join departments dp on (pl.root_customer_id = dp.ksazd_id)
      inner join ksazd.specifications s on (ps.id = s.plan_specification_id)
      inner join ksazd.lots l on (s.lot_id = l.id)
      inner join ksazd.winner_protocols wp on (l.winner_protocol_id = wp.id)
      inner join ksazd.winner_protocol_lots wpl on (wpl.winner_protocol_id = wp.id and wpl.lot_id = l.id)
    where pl.status_id in (#{plan_statuses})
      and pl.gkpz_year >= #{START_YEAR}
      and wpl.updated_at > :max_time
      and l.root_customer_id in (2,8)
    group by ps.guid
  SQL

  private

  def changed_data_sql
    CHANGED_DATA_SQL
  end
end
