require 'db/model'

class PlanLot < Model
  attributes :gkpz_year, :num_tender, :num_lot, :department_id,
             :tender_type_id, :tender_type_explanations, :subject_type_id,
             :etp_address_id, :announce_date, :explanations_doc, :point_clause,
             :protocol_id, :commission_id, :additional_to, :state, :additional_num,
             :status_id
  schema :ksazd
end
