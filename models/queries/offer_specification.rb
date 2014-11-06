require 'db/query'

class OfferSpecification < Query
  private

  def changed_data
    DB.query_all(<<-sql, maximum_modified_time)
      select ps.guid, null, max(os.updated_at)
        from ksazd.protocols p,
             ksazd.commissions c,
             ksazd.plan_lots pl,
             ksazd.plan_specifications ps,
             directions d,
             --
             ksazd.specifications s,
             ksazd.offer_specifications os
        where p.commission_id = c.id
          and c.commission_type_id in (#{commission_types})
          and p.id = pl.protocol_id
          and pl.id = ps.plan_lot_id
          and ps.direction_id = d.ksazd_id
          --
          and ps.id = s.plan_specification_id
          and s.id = os.specification_id
          --
          and pl.status_id in (#{plan_statuses})
          and pl.gkpz_year >= #{START_YEAR}
          and os.updated_at > :max_time
        group by ps.guid
    sql
  end
end
