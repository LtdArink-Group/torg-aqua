require './db/db'

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

    def find(id)
      self.new(id).tap { |s| s.load }
    end
  end

  def initialize(id)
    @id = id
  end

  def load
    @values = DB.query_first_row(sql)
  end

  private

  def fields
    @fields ||= self.class.instance_variable_get(:@attributes).join(', ')
  end

  def schema
    @schema ||= self.class.instance_variables.include?(:@schema) ?
                self.class.instance_variable_get(:@schema) + '.' : ''
  end

  def table_name
    self.class.to_s.scan(/[A-Z][a-z]+/).map(&:downcase).join('_') + 's'
  end

  def table
    @table ||= schema + table_name
  end

  def id_field
    @id_field ||= self.class.instance_variable_get(:@id_field) || 'id'
  end

  attr_reader :id

  def sql
    "select #{fields} from #{table} where #{id_field} = #{DB.encode(id)}"
  end
end
