require 'db/db'

class Sequence
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def deploy
    create unless exists?
  end

  def nextval
    DB.query_value(<<-sql)
      select #{name}.nextval from dual
    sql
  end

  private

  def create
    DB.exec "create sequence #{name}"
  end

  def exists?
    query = <<-sql
      select count(*)
        from user_sequences
        where sequence_name = upper('#{name}')
    sql
    DB.query_value(query) > 0
  end
end
