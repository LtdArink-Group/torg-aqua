require './db/db'

class Model
  def self.find(id)
    self.new(id).tap { |s| s.load }
  end

  def initialize(id)
    @id = id
  end

  def load
    @values = DB.query_first_row(sql)
  end

  private

  def sql
    "select %d from dual" % @id
  end
end
