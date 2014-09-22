require './db/model'

class Department < Model
  def aqua_id
    @values[0]
  end

  private

  def sql
    "select aqua_id from departments where ksazd_id = #{@id}"
  end
end