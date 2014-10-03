require 'db/model'

class WinnerProtocol < Model
  attributes :confirm_date
  schema :ksazd
end

NullWinnerProtocol = Struct.new(:confirm_date)
