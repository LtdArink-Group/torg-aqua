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

    def id_field(symbol)
      @id_field = symbol.to_s
    end

    def where(hash)
      @where = hash
    end

    def find(id)
      model = self.new(id).tap { |s| s.load }
      model.values ? model : nil
    end
  end

  def initialize(id)
    @id = id
  end

  def load
    @values = DB.query_first_row(sql)
  end

  attr_reader :values

  private

  def fields
    self.class.instance_variable_get(:@attributes).join(', ')
  end

  def schema
    if self.class.instance_variables.include?(:@schema)
      self.class.instance_variable_get(:@schema) + '.'
    else
      ''
    end
  end

  def table_name
    @table_name ||= self.class.to_s.scan(/[A-Z][a-z]+/).map(&:downcase).join('_')
  end

  def table_suffix
    %w{s x}.include?(table_name[-1]) ? 'es' : 's'
  end

  def table
    schema + table_name + table_suffix
  end

  def id_field
    self.class.instance_variable_get(:@id_field) || 'id'
  end

  def additional_conditions
    if self.class.instance_variables.include?(:@where)
      self.class.instance_variable_get(:@where).map do |field, value|
        " and #{field} = #{DB.encode(value)}"
      end.join
    end
  end

  def sql
    "select #{fields} from #{table} " \
    "where #{id_field} = #{DB.encode(@id)}" \
    "#{additional_conditions}"
  end
end
