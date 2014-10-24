require 'aqua/soap_client'

class ProjectsEndpoint
  def self.query(from, to)
    new(from, to)
  end

  def initialize(from, to)
    config = Configuration.soap.project
    @params = { iv_date_fr: from, iv_date_to: to, iv_syst_id: config.system }
    @client = SoapClient.new(config.wsdl, config.login, config.password)
  end

  def status
    body[:es_ret][:type]
  end

  def message
    body[:es_ret][:message]
  end

  def data
    @data ||= begin
      data = body[:et_project][:item]
      data.is_a?(Hash) ? [data] : data
    end
  end

  private

  attr_reader :params, :client

  def response
    @response ||= client.call :zppm_proj_upload, message: params
  end

  def body
    response.body[:zppm_proj_upload_response]
  end
end
