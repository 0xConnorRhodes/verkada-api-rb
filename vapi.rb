require 'httparty'
require 'json'

class Vapi
  include HTTParty
  base_uri 'https://api.verkada.com'

  def initialize(api_key)
    @api_key = api_key
    @token = nil
    @token_expiry = nil
  end

  def get_api_token
    response = self.class.post('/token', {
      headers: {
        'Content-Type' => 'application/json',
        'x-api-key' => @api_key
      }
    })

    if response.success?
      @token = response["token"]
      # Token expires in 30 minutes, store expiry time 29:50 in the future
      @token_expiry = Time.now + 1790
      @token
    else
      raise "Failed to get token: #{response.code} - #{response.body}"
    end
  end

  def get_camera_data
    get_api_token if token_expired?

    response = self.class.get('/cameras/v1/devices', {
      headers: {
        'Content-Type' => 'application/json',
        'x-verkada-auth': @token
      }})

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    else
      raise "Failed to get camera info: #{response.code} - #{response.body}"
    end
  end

  private

  def token_expired?
    return true if @token.nil? || @token_expiry.nil?
    Time.now >= @token_expiry
  end
end