require 'oci8'
require 'config/configuration'

class DB
  class << self
    def query_value(query, *args)
      exec(query, *args).fetch[0]
    end

    def query_first_row(query, *args)
      exec(query, *args).fetch
    end

    def query_all(query, *args)
      [].tap do |a|
        exec(query, *args) { |r| a << r }
      end
    end

    def exec(statement, *args, &block)
      log(statement) do
        connection.exec(statement, *args, &block)
      end
    end

    def commit
      connection.commit
    end

    def connection
      @connection ||= OCI8.new(Configuration.database.login,
                               Configuration.database.password,
                               Configuration.database.tns)
    end

    def log(statement)
      start = Time.now
      result = yield
      delta = (Time.now - start) * 1_000
      statement = statement.gsub(/--.*$/, '').gsub(/\s+/, ' ').strip
      puts format("SQL (%.1fms) '%s'", delta, statement)
      result
    end

    def encode(val)
      if val.nil?
        'null'
      else
        val.is_a?(String) ? "'#{val}'" : val
      end
    end

    def guid(data)
      data.bytes.map { |b| sprintf('%02X', b) }.join if data
    end
  end
end
