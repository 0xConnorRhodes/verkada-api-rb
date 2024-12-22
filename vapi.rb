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
  # Retrieve a list of doors. Optionally based on the passed door ids or site ids
  #
  # @param door_ids [Array<String>] list of door ids to retrieve
  # @param site_ids [Array<String>] list of site ids to retrieve
    get_api_token if token_expired?

    headers = {
      'accept' => 'application/json',
      'x-verkada-auth' => @token
    }

    query = {}
    query[:door_ids] = door_ids.join(',') if door_ids
    query[:site_ids] = site_ids.join(',') if site_ids

    response = self.class.get('/access/v1/doors', headers: headers, query: query)

    unless response.success?
      raise "Failed to get list of doors: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body, symbolize_names: true)[:doors]
  end

  def unlock_door_as_admin(door_id)
    get_api_token if token_expired?

    headers = {
      'accept' => 'application/json',
      'content-type' => 'application/json',
      'x-verkada-auth' => @token
    }

    payload = { door_id: door_id }.to_json

    response = self.class.post("/access/v1/door/admin_unlock", headers: headers, body: payload)

    unless response.success?
      raise "Failed to unlock door: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body, symbolize_names: true)
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

  def create_helix_event_type(name:, schema:)
    get_api_token if token_expired?

    headers = {
      'accept' => 'application/json',
      'content-type' => 'application/json',
      'x-verkada-auth' => @token
    }

    payload = { name: name, event_schema: schema }.to_json

    response = self.class.post("/cameras/v1/video_tagging/event_type", headers: headers, body: payload)

    unless response.success?
      raise "Failed to create helix event type: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body, symbolize_names: true)
  end

  def update_helix_event_type(uid:, name:, schema:)
  # Updates a Helix event type. All non-UID info overwrites existing info
  #
  # @param uid [String] The event type's UID
  # @param name [String] The event type's name
  # @param schema [Hash] The event type's schema
  #
  # @return [Integer] The HTTP response code (no body)

    get_api_token if token_expired?

    query = { event_type_uid: uid }

    headers = {
      'content-type' => 'application/json',
      'x-verkada-auth' => @token
    }

    payload = { name: name, event_schema: schema }.to_json  

    response = self.class.patch("/cameras/v1/video_tagging/event_type", query: query, headers: headers, body: payload)

    unless response.success?
      raise "Failed to update helix event type: #{response.code} - #{response.body}"
    end

    response.code
  end

  private

  def token_expired?
    return true if @token.nil? || @token_expiry.nil?
    Time.now >= @token_expiry
  end
end