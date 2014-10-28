require 'models/queries'
require 'models/aqua_lot'

class NewLots
  def self.process
    ps = PlanSpecification.new
    ps.data.each do |lot|
      AquaLot.new(*lot[0,2]).pending
    end
    ps.save_maximum_time unless ps.data.empty?
  end
end
