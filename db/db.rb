require 'oci8'

class DB
  def self.query_value(query)
    exec(query).fetch[0]
  end

  def self.query_first_row(query)
    exec(query).fetch
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
    statement.gsub!(/--.*$/,'').gsub!(/\s+/,' ').strip!
    puts "SQL (%.1fms) '%s'" % [delta, statement]
    result
  end

  def self.encode(val)
    val.nil? ? 'null' : val.is_a?(String) ? "'#{val}'" : val
  end
end
