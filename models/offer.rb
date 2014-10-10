require 'db/model'

class Offer < Model
  attributes :contractor_id, :num, :type_id, :status_id, :rebidded,
             :absent_auction, :cost, :cost_nds, :final_cost, :final_cost_nds
  attr_accessor :contractor
end
