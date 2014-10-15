require 'soap/client'

module SOAP
  class Projects
    def initialize(from, to)
      @params = {
        'IV_DATE_FR' => from,
        'IV_DATE_TO' => to,
        'IV_SYST_ID' => '02'
      }
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

    attr_reader :params

    def response
      @response ||= SOAP::Client.call :zppm_proj_upload, message: params
    end

    def body
      response.body[:zppm_proj_upload_response]
    end
  end
end
