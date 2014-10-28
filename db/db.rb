require 'oci8'
require 'config/configuration'

class DB
  def self.query_value(query, *args)
    exec(query, *args).fetch[0]
  end

  def self.query_first_row(query, *args)
    exec(query, *args).fetch
  end

  def self.query_all(query, *args)
    [].tap do |a|
      exec(query, *args) { |r| a << r }
    end
  end

  def self.exec(statement, *args, &block)
    log(statement) do
      connection.exec(statement, *args, &block)
    end
  end

  def self.commit
    connection.commit
  end

  def self.connection
    @connection ||= OCI8.new(Configuration.database.login,
                             Configuration.database.password,
                             Configuration.database.tns)
  end

  def self.log(statement)
    start = Time.now
    result = yield
    delta = (Time.now - start) * 1_000
    statement = statement.gsub(/--.*$/, '').gsub(/\s+/, ' ').strip
    puts format("SQL (%.1fms) '%s'", delta, statement)
    result
  end

  def self.encode(val)
    if val.nil?
      'null'
    else
      val.is_a?(String) ? "'#{val}'" : val
    end
  end
end
