require 'yaml'
require './db/table'
require './db/sequence'

class Schema
  def initialize(file_name)
    schema = YAML.load_file(file_name)
    @tables = schema['tables']
    @sequences = schema['sequences']
  end

  def deploy
    deploy_tables
    deploy_sequences
  end

  private

  def deploy_tables
    @tables.each { |name, fields| Table.new(name).deploy(fields) }
  end

  def deploy_sequences
    @sequences.each { |name| Sequence.new(name).deploy }
  end
end
