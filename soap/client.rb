require 'savon'

module SOAP
  class Client
    def client
      @client ||= Savon.client(wsdl: '../zppm_projc_upload_17092014_in.wsdl',
                               proxy: 'http://zyablickiy_ss:asdfG1hjkl@172.30.45.131:8080/',
                               basic_auth: %w(1c, 1c123456),
                               convert_request_keys_to: :upcase)
    end

    def params
      { 'IV_DATE_FR' => '01.01.2014', 'IV_DATE_TO' => '31.12.2014',
        'IV_SYST_ID' => '01' }
    end

    def operation
      :zppm_proj_upload
    end

    def response
      client.call operation, message: params
    end

    def data
      @data ||= response.body[:zppm_proj_upload_response][:et_project][:item]
    end
  end
end
