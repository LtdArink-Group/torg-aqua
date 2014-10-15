require 'savon'
require 'config/configuration'

module SOAP
  class Client
    class << self
      def call(operation_name, locals = {}, &block)
        client.call(operation_name, locals, &block)
      end

      def client
        @client ||= Savon.client(options)
      end

      def options
        options = {}.tap do |o|
          o.merge! proxy: Configuration.soap.proxy if Configuration.soap.proxy
        end
        options.merge(
          wsdl: Configuration.soap.wsdl,
          basic_auth: [Configuration.soap.login, Configuration.soap.password],
          convert_request_keys_to: :upcase
        )
      end
    end
  end
end
