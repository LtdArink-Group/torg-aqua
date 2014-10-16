require 'savon'
require 'config/configuration'

class SoapClient
  def initialize(wsdl, login, password)
    @wsdl, @login, @password = wsdl, login, password
  end

  def call(operation_name, locals = {}, &block)
    client.call(operation_name, locals, &block)
  end

  private

  attr_reader :wsdl, :login, :password

  def client
    @client ||= Savon.client(options)
  end

  def options
    options = {}.tap do |o|
      o.merge! proxy: Configuration.soap.proxy if Configuration.soap.proxy
    end
    options.merge(wsdl: wsdl, basic_auth: [login, password],
                  convert_request_keys_to: :upcase)
  end
end
