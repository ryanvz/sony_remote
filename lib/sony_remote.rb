require 'restclient'
require 'nokogiri'
require 'active_support/inflector'

class SonyRemote
  attr_accessor :device_name, :device_id
  #temporary

  def commands
    @commands.keys
  end

  def command(name)
    request = %Q~<?xml version="1.0"?>
    <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
      <s:Body>
        <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
          <IRCCCode>#{@commands[name]}</IRCCCode>
        </u:X_SendIRCC>
      </s:Body>
    </s:Envelope>~
    post '/IRCC', request
  end

  def initialize(address)
    @address = address
    @device_name = 'Sony Gem'
    @device_id = 'sony_gem'
    register
    load_commands
  end

  def get(location)
    Nokogiri.parse RestClient.get("#{@address}#{location}", headers)
  end

  def post(location, payload)
    Nokogiri.parse RestClient.post("#{@address}#{location}", payload, headers)
  end

  def headers
    {'X-CERS-DEVICE-ID' => device_id}
  end

  def get_text
    get '/cers/api/getText'
  end

  def send_text(text)
    get "/cers/api/sendText?text=#{URI.encode(text)}"
  end

  def actions
    get('/cers/ActionList.xml').search('action').map{|a| a.attr('name')}
  end

  def status
    get('/cers/api/getStatus').search('status *').inject({}) do |result, status|
      result[status.attr('field')] = status.attr('value')
      result
    end
  end

  def system_info
    s.get('/cers/api/getSystemInformation')
  end

  def system_name
    system_info.search('name').text
  end

  def register
    get "/cers/api/register?name=#{URI.encode(device_name)}&registrAtionType=renewal&deviceId=#{URI.encode(device_id)}"
  end

  def load_commands
    @commands = get("/cers/api/getRemoteCommandList").search('command').inject({}) do |result, command|
      result[command.attr('name')] = command.attr('value') if command.attr('type') == 'ircc'
      result
    end

    @commands.each_key do |name|
      define_singleton_method name.underscore do
        command name
      end
    end
  end

end
