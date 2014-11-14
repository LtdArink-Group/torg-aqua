require 'db/db'

class Model
  class << self
    def attributes(*args)
      @attributes = args.map(&:to_s)
      @attributes.each_with_index do |name, index|
        define_method(name) { @values[index] }
      end
    end

    def schema(symbol)
      @schema = symbol.to_s
    end

    def tablename(symbol)
      @tablename = symbol.to_s
    end

    def id_field(symbol)
      @id_fields = [symbol.to_s]
    end

    def id_fields(*symbols)
      @id_fields = symbols.map(&:to_s)
    end

    def where(hash)
      @where = hash
    end

    def find(*ids)
      model = new(*ids).tap(&:load)
      model.values ? model : nil
    end

    def create(values_hash)
      DB.exec(<<-sql)
        insert into #{table} (#{ values_hash.keys.map(&:to_s).join(', ') })
          values (#{ values_hash.values.map { |val| DB.encode(val) }.join(', ') })
      sql
      DB.commit
    end

    def schema_name
      @schema ? @schema + '.' : ''
    end

    def table_name
      @table_name ||= to_s.scan(/[A-Z][a-z]+/).map(&:downcase).join('_')
    end

    def table_name_pluralized
      if table_name.end_with?('y')
        table_name[0..-2] + 'ies'
      else
        table_name + table_suffix
      end
    end

    def table_suffix
      %w(s x).include?(table_name[-1]) ? 'es' : 's'
    end

    def table
      schema_name + (@tablename || table_name_pluralized)
    end
  end

  def initialize(*ids)
    @ids = ids
  end

  def load
    @values = DB.query_first_row(sql)
  end

  attr_accessor :values

  private

  def fields
    self.class.instance_variable_get(:@attributes).join(', ')
  end

  def id_fields
    self.class.instance_variable_get(:@id_fields) || ['id']
  end

  def id_conditions
    id_fields.each_with_index.map do |id, i|
      "#{id} = #{DB.encode(@ids[i])}"
    end.join(' and ')
  end

  def additional_conditions
    return unless self.class.instance_variables.include?(:@where)
    self.class.instance_variable_get(:@where).map do |field, value|
      " and #{field} = #{DB.encode(value)}"
    end.join
  end

  def sql
    "select #{fields} from #{self.class.table} " \
    "where #{id_conditions}#{additional_conditions}"
  end
end
