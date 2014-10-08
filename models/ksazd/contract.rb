require 'db/model'

class Contract < Model
  MAIN_CONTRACT = 37001 # Основной договор

  attributes :confirm_date
  schema :ksazd
  id_field :lot_id
  where type_id: MAIN_CONTRACT
end

NullContract = Struct.new(:confirm_date)
