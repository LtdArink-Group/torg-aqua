require 'db/model'

class OpenProtocol < Model
  attributes :open_date
  schema :ksazd
  id_field :tender_id
end

NullOpenProtocol = Struct.new(:open_date)
