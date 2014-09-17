require 'yaml'
require './db/table'

class Seed
  def initialize(file_name)
    @tables = YAML.load_file(file_name)
  end

  def apply
    @tables.each do |name, values|
      Table.new(name).apply(values)
    end
  end
end
