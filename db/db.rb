require 'oci8'

class DB
  def self.query(query)
    connection.exec(query)
  end

  def self.query_value(query)
    connection.exec(query).fetch[0]
  end

  def self.connection
    @connection ||= OCI8.new('ksazd2aqua', 'ksazd2aqua', 'ksazd_backup')
  end
end
