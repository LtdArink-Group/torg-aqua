require './db/db'

class Table
  def initialize(name)
    @name = name
  end

  def deploy(fields)
    @fields = fields
    drop if exists?
    create
  end

  def apply(values)
    truncate
    values.each { |row| insert(row) }
    DB.commit
  end

  private

  def drop 
    DB.exec "drop table #{@name}"
  end

  def truncate
    DB.exec "truncate table #{@name}"
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
    @fields.map { |name, type| "#{name} #{type}" }.join(',')
  end

  def insert(row)
    DB.exec "insert into #{@name} values (#{insert_values(row)})"
  end

  def insert_values(list)
    list.map { |v| DB.encode(v) }.join(',')
  end
end
