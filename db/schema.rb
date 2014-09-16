require 'yaml'
require './db/table'

class Schema
  def self.deploy
  end

  def initialize(file_name)
    @tables = YAML.load_file(file_name)
  end

  def deploy
    @tables.each do |name, attributes|
      Table.new(name, attributes).deploy
    end
  end
end
