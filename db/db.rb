require 'oci8'

class DB
  def self.exec(statement)
    p statement
    connection.exec(statement)
  end

  def self.query_value(query)
    connection.exec(query).fetch[0]
  end

  def self.connection
    @connection ||= OCI8.new('ksazd2aqua_test', 'ksazd2aqua', 'ksazd_backup')
  end
end
