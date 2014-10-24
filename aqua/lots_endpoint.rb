require 'aqua/soap_client'

class LotsEndpoint
  def self.send(data)
    new(data)
  end

  def initialize(data)
    config = Configuration.soap.lot
    @client = SoapClient.new(config.wsdl, config.login, config.password)
    @data = data
  end

  def response
    @response ||= client.call :zfm_ppm_lots_ksazd_in_ws, message: data
  end

  def status
    body[:status].to_i
  end

  def message
    body[:statxt]
  end

  private

  attr_reader :client, :data

  def body
    response.body[:zfm_ppm_lots_ksazd_in_ws_response][:status_ret]
  end
end
