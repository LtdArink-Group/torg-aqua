require 'oci8'

class DB
  def self.query_value(query)
    exec(query).fetch[0]
  end

  def self.exec(statement)
    log(statement) do
      connection.exec(statement)
    end
  end

  def self.commit
    connection.commit
  end

  def self.connection
    @connection ||= OCI8.new('ksazd2aqua_test', 'ksazd2aqua', 'ksazd_backup')
  end

  def self.log(statement)
    start = Time.now
    result = yield
    delta = (Time.now - start) * 1_000
    puts "SQL (%.1fms) '%s'" % [delta, statement.gsub(/\s+/,' ').strip]
    result
  end

  def self.to_s(val)
    val.nil? ? 'null' : val.is_a?(String) ? "'#{val}'" : val
  end
end
