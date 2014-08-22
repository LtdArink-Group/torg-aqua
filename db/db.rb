require 'oci8'

class DB
  def self.exec_query(query)
    connection.exec query
  end

  def self.connection
    @connection ||= OCI8.new('ksazd','ksazd','ksazd_primary')
  end
end
