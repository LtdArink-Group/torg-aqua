require 'db/model'

class Protocol < Model
  attributes :num, :date_confirm
  schema :ksazd

  def details
    "протокол №#{num} от #{date_confirm.strftime('%d.%m.%Y')}"
  end
end
