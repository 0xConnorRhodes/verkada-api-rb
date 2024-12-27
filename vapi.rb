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

  def get_camera_data(data_key: :cameras, page_size: 100)
    get_api_token if token_expired?

    uri = '/cameras/v1/devices'
    query = { page_size: page_size }
    headers = {
      'Content-Type' => 'application/json',
      'x-verkada-auth' => @token
    }
    return get_pages(uri, query, headers, data_key: data_key)
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

    body = { door_id: door_id }.to_json

    response = self.class.post("/access/v1/door/admin_unlock", headers: headers, body: body)

    unless response.success?
      raise "Failed to unlock door: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body, symbolize_names: true)
  end

  def get_helix_event_types(symbolize_names: true)
    get_api_token if token_expired?

    headers = {
      'accept' => 'application/json',
      'x-verkada-auth' => @token
    }

    response = self.class.get('/cameras/v1/video_tagging/event_type', headers: headers)

    unless response.success?
      raise "Failed to get list of helix event types: #{response.code} - #{response.body}"
    end

    if symbolize_names
      JSON.parse(response.body, symbolize_names: true)[:event_types]
    else
      JSON.parse(response.body, symbolize_names: false)["event_types"]
    end
  end

  def create_helix_event_type(name:, schema:)
    get_api_token if token_expired?

    headers = {
      'accept' => 'application/json',
      'content-type' => 'application/json',
      'x-verkada-auth' => @token
    }

    body = { name: name, event_schema: schema }.to_json

    response = self.class.post("/cameras/v1/video_tagging/event_type", headers: headers, body: body)

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
  # @return [Integer] The HTTP response code

    get_api_token if token_expired?

    query = { event_type_uid: uid }

    headers = {
      'content-type' => 'application/json',
      'x-verkada-auth' => @token
    }

    body = { name: name, event_schema: schema }.to_json  

    response = self.class.patch("/cameras/v1/video_tagging/event_type", query: query, headers: headers, body: body)

    unless response.success?
      raise "Failed to update helix event type: #{response.code} - #{response.body}"
    end

    response.code
  end

  def create_helix_event(event_type_uid:, camera_id:, flagged: false, attributes:, time: nil)
  # Creates a new Helix event.
  #
  # @param event_type_uid [String] The UID of the event type to create the event for
  # @param camera_id [String] The ID of the camera to create the event for
  # @param flagged [Boolean] Whether the event should be flagged. Defaults to false.
  # @param attributes [Hash] The attributes of the event
  # @param time [Integer] The time of the event in milliseconds. Defaults to the current time.
  #
  # @return [Integer] The HTTP response code

    get_api_token if token_expired?

    time = time.nil? ? (Time.now.to_f * 1000).round : time

    headers = {
      'content-type' => 'application/json',
      'x-verkada-auth' => @token
    }

    body = { 
      event_type_uid: event_type_uid, 
      camera_id: camera_id, 
      flagged: flagged, 
      attributes: attributes, 
      time_ms: time
    }.to_json

    response = self.class.post("/cameras/v1/video_tagging/event", headers: headers, body: body)

    unless response.success?
      raise "Failed to create helix event: #{response.code} - #{response.body}"
    end

    response.code
  end

  def get_audit_logs(data_key: :audit_logs, page_size: 100)
    get_api_token if token_expired?

    uri = '/core/v1/audit_log'
    query = { page_size: page_size }
    headers = {
      'accept' => 'application/json',
      'x-verkada-auth' => @token
    }
    return get_pages(uri, query, headers)
  end

  private

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

  def token_expired?
    return true if @token.nil? || @token_expiry.nil?
    Time.now >= @token_expiry
  end

  def get_pages(uri, query, headers, data_key: :audit_logs)
    entries = nil
    next_page_token = nil

    loop do
      query[:page_token] = next_page_token if next_page_token

      response = self.class.get(uri, query: query, headers: headers)

      unless response.success?
        raise "Failed to get data: #{response.code} - #{response.body}"
      end

      page_data = JSON.parse(response.body, symbolize_names: true)

      if entries.nil?
        entries = page_data[data_key]
      else
        entries.concat(page_data[data_key])
      end

      next_page_token = page_data[:next_page_token]
      break if next_page_token.nil?
    end
    entries
  end
end
