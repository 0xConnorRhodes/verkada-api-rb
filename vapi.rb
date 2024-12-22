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

    cameras = nil
    next_page_token = nil

    loop do
      uri = '/cameras/v1/devices'
      query = { page_size: 100 }
      query[:page_token] = next_page_token if next_page_token

      headers = {
        'Content-Type' => 'application/json',
        'x-verkada-auth' => @token
      }

      response = self.class.get(uri, headers: headers, query: query)

      unless response.success?
        raise "Failed to get camera info: #{response.code} - #{response.body}"
      end

      page_data = JSON.parse(response.body, symbolize_names: true)

      if cameras.nil?
        cameras = page_data[:cameras]
      else
        cameras.concat(page_data[:cameras])
      end

      next_page_token = page_data[:next_page_token]
      break if next_page_token.nil?
    end
    cameras
  end

  def get_doors(door_ids: nil, site_ids: nil)
    get_api_token if token_expired?

    headers = {
      'accept' => 'application/json',
      'x-verkada-auth' => @token
    }

    query = {}
    # pass door or site ids as array of strings: ['id1'] / ['id1', 'id2']
    query[:door_ids] = door_ids.join(',') if door_ids
    query[:site_ids] = site_ids.join(',') if site_ids

    response = self.class.get('/access/v1/doors', headers: headers, query: query)

    unless response.success?
      raise "Failed to get list of doors: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body, symbolize_names: true)[:doors]
  end

  def get_helix_event_types
    get_api_token if token_expired?

    headers = {
      'accept' => 'application/json',
      'x-verkada-auth' => @token
    }

    response = self.class.get('/cameras/v1/video_tagging/event_type', headers: headers)

    unless response.success?
      raise "Failed to get list of helix event types: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body, symbolize_names: true)[:event_types]
  end

  private

  def token_expired?
    return true if @token.nil? || @token_expiry.nil?
    Time.now >= @token_expiry
  end
end