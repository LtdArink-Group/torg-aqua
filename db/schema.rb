require 'yaml'
require './db/table'

class Schema
  def initialize(file_name)
    @tables = YAML.load_file(file_name)
  end

  def deploy
    @tables.each do |name, fields|
      Table.new(name).deploy(fields)
    end
  end
end