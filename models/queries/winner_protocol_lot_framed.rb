require 'db/query'

class Query::WinnerProtocolLotFramed < Query::Base
  CHANGED_DATA_SQL = <<-SQL
    select
      ps.guid, s.guid, max(wp.updated_at)
    from ksazd.protocols p
      inner join ksazd.commissions c on (p.commission_id = c.id and c.commission_type_id in (#{commission_types}))
      inner join ksazd.plan_lots pl on (p.id = pl.protocol_id)
      inner join ksazd.plan_specifications ps on (pl.id = ps.plan_lot_id)
      inner join directions d on (ps.direction_id = d.ksazd_id)
      inner join departments dp on (pl.root_customer_id = dp.ksazd_id)
      inner join ksazd.specifications fs on (ps.id = fs.plan_specification_id)
      inner join ksazd.specifications s on (fs.id = s.frame_id)
      inner join ksazd.lots l on (s.lot_id = l.id)
      inner join ksazd.winner_protocols wp on (l.winner_protocol_id = wp.id)
      inner join ksazd.winner_protocol_lots wpl on (wpl.winner_protocol_id = wp.id and wpl.lot_id = l.id)
    where pl.status_id in (#{plan_statuses})
      and pl.gkpz_year >= #{START_YEAR}
      and wpl.updated_at > :max_time
      and l.root_customer_id in (2, 3, 4, 5, 6, 7, 8, 9, 701000, 702000, 801000, 906000, 1000011)
    group by ps.guid, s.guid
  SQL

  private

  def changed_data_sql
    CHANGED_DATA_SQL
  end
end
