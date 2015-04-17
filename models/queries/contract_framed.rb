require 'db/query'

class Query::ContractFramed < Query::Base
  CHANGED_DATA_SQL = <<-SQL
    select ps.guid, s.guid, max(ct.updated_at)
      from ksazd.protocols p,
           ksazd.commissions c,
           ksazd.plan_lots pl,
           ksazd.plan_specifications ps,
           directions d,
           departments dp,
           --
           ksazd.specifications fs,
           ksazd.specifications s,
           ksazd.lots l,
           ksazd.contracts ct
      where p.commission_id = c.id
        and c.commission_type_id in (#{commission_types})
        and p.id = pl.protocol_id
        and pl.id = ps.plan_lot_id
        and ps.direction_id = d.ksazd_id
        and pl.root_customer_id = dp.ksazd_id
        --
        and ps.id = fs.plan_specification_id
        and fs.id = s.frame_id
        and s.lot_id = l.id
        and l.id = ct.lot_id
        --
        and pl.status_id in (#{plan_statuses})
        and pl.gkpz_year >= #{START_YEAR}
        and ct.updated_at > :max_time
        and l.root_customer_id in (2, 3, 4, 5, 6, 7, 8, 9, 701000, 702000, 801000, 906000, 1000011)
      group by ps.guid, s.guid
  SQL

  private

  def changed_data_sql
    CHANGED_DATA_SQL
  end
end
