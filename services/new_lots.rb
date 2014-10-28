require 'models/queries'
require 'models/aqua_lot'

class NewLots
  class << self
    def process
      detect_changes
      update_aqua
    end

    def detect_changes
      Query.descendants.each do |klass|
        ps = klass.new
        ps.data.each do |lot|
          AquaLot.new(*lot[0, 2]).pending
        end
        ps.save_maximum_time unless ps.data.empty?
      end
    end

    def update_aqua
    end
  end
end
