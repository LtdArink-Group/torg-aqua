require './db/db'

class Table
  def initialize(name, attributes)
    @name = name
    @attributes = attributes
  end

  def deploy
    drop if exists?
    create
  end

  private

  def drop 
    DB.exec "drop table #{@name}"
  end

  def exists?
    query = <<-sql
      select count(*)
        from user_tables
        where table_name = upper('#{@name}')
    sql
    DB.query_value(query) > 0
  end

  def create
    DB.exec "create table #{@name} (#{fields_list})"
  end

  def fields_list
    @attributes['fields'].map { |name, type| "#{name} #{type}" }.join(',')
  end
end
