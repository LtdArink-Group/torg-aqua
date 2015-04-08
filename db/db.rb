require 'oci8'
require 'config/configuration'

class DB
  class << self
    def query_value(query, *args)
      cursor = exec(query, *args)
      val = cursor.fetch[0]
      cursor.close
      val
    end

    def query_first_row(query, *args)
      cursor = exec(query, *args)
      val = cursor.fetch
      cursor.close
      val
    end

    def query_all(query, *args)
      [].tap do |a|
        cursor = exec(query, *args)
        while r = cursor.fetch
          a << r
        end
        cursor.close
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

      @connection.exec("ALTER SESSION SET TIME_ZONE = '+00:00'")
      @connection
    end

    def log(statement)
      start = Time.now
      begin
        result = yield
      rescue => e
        puts statement
        raise e
      end
      delta = (Time.now - start) * 1_000
      statement = statement.gsub(/--.*$/, '').gsub(/\s+/, ' ').strip
      puts format("SQL (%.1fms) '%s'", delta, statement)
      result
    end

    def encode(val)
      val.nil? ? 'null' : encode_type(val)
    end

    def encode_type(val)
      case val
      when String then "'#{val.gsub("'", "''")}'"
      when Time then encode_time(val)
      else val
      end
    end

    def encode_time(time)
      time_string = time.strftime('%Y-%m-%d %H:%M:%S')
      "to_date('#{time_string}', 'YYYY-MM-DD HH24:MI:SS')"
    end

    def guid(data)
      data.bytes.map { |b| sprintf('%02X', b) }.join if data
    end
  end
end
