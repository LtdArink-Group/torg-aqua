require 'db/model'

class Contractor < Model
  attributes :id, :fullname, :inn, :kpp
  schema :ksazd
end
