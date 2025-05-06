# verkada-api-rb
Verkada API wrapper in ruby

Module is located in `lib/vapi.rb`.

## Methods

### get_org_id
Retrieves the organization ID of the currently active API key.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
org_id = vapi.get_org_id
```

### get_camera_data
Fetches camera device data with pagination support, returning an array of cameras.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
cameras = vapi.get_camera_data
```

### get_doors
Retrieves a list of doors, optionally filtered by door IDs or site IDs.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
doors = vapi.get_doors
filtered_doors = vapi.get_doors(site_ids: ['site123'], door_ids: ['door456'])
```

### unlock_door_as_admin
Unlocks a door immediately using an API key irrespective of any user's door access privileges.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
vapi.unlock_door_as_admin('door_id_456')
```

### get_helix_event_types
Lists all Helix video tagging event types, with an option to symbolize JSON keys.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
event_types = vapi.get_helix_event_types
```

### create_helix_event_type
Creates a new Helix event type with the given name and schema definition.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
schema = { object: 'string', count: 'integer' }
vapi.create_helix_event_type(name: 'MyEventType', schema: schema)
```

### update_helix_event_type
Updates the name and schema of an existing Helix event type by UID. Supports renaming an existing event type and/or overwriting its existing schema with the newly provided one.

```ruby
vapi = Vapi.new('YOUR_API_KEY')

new_schema = { 
  object: 'string', 
  count: 'integer',
  temperature: 'float'  
}

vapi.update_helix_event_type(uid: 'evt123', name: 'New Name', schema: new_schema)
```

### delete_helix_event_type
Deletes a Helix event type identified by its UID.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
vapi.delete_helix_event_type('evt123')
```

### create_helix_event
Creates a new Helix tagging event for a camera, including attributes and optional timestamp.

```ruby
client = Vapi.new('YOUR_API_KEY')

# attributes from helix event type
attrs = { 
  location: 'Front Door',
  object_count: 2 
}

status = client.create_helix_event(
  event_type_uid: 'evt123', 
  camera_id: 'cam789', 
  attributes: attrs,
  flagged: true, # optional
  time: Time.now.to_i * 1000 # optional, must be in milliseconds
)
```

### get_ot_data
Retrieves occupancy trend analytics for a camera over a specified interval and type.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
ot_data = vapi.get_ot_data(
  camera_id: 'cam789', 
  interval: '1_hour', 
  type: 'person'
)
```

### get_audit_logs
Fetches audit log entries between given start and end times, with pagination.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
logs = vapi.get_audit_logs(
  start_time: Time.now.to_i - (24 * 60 * 60), # 24 hours in the past
  end_time: Time.now.to_i # Unix time in seconds
)
```

### get_access_users
Lists all access control users for the organization.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
users = vapi.get_access_users
```

### get_guest_visits
Retrieves guest visits for a site over a time range, automatically chunking by day if needed.

```ruby
vapi = Vapi.new('YOUR_API_KEY')
visits = vapi.get_guest_visits(
  site_id: 'site123', 
    start_time: Time.now.to_i - (7 * 24 * 60 * 60), # 7 days in the past
    end_time: Time.now.to_i) # Current time in seconds
```

## Private Functions
The module includes private functions which are reused throughout multiple public methods. These functions can found beneath the `private` keyword in `lib/vapi.rb` and may be adapted for use in other scripts.

### get_api_token
Get ephemeral access token from the supplied API key

```ruby
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
```

### token_expired?
Check if the currently active token is expired. If the existing token is still active, it will be used for future calls. If it is close to expiration, a new token will be generated.

```ruby
def token_expired?
  return true if @token.nil? || @token_expiry.nil?
  Time.now >= @token_expiry
end
```

### get_pages
This function handles pagination across multiple Verkada endpoints. This enables pagination on all supported endpoints, and allows for chunking multiple requests together for endpoints with limited time-range support. (Such as `get_guest_visits`)

```ruby
def get_pages(uri, query, headers, data_key: :audit_logs, page_count: 'all')
# loop through get requests providing next_page_token if present
# append each array of responses to a combined array which is returned at the end
# 
# data_key: specifies the name of the key in the returned object which contains the
# array of responses (eg :cameras in get_camera_data, :visits in get_guest_visits etc.)

  entries = nil
  next_page_token = nil

  if page_count == 'all'
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
  else
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

      page_count -= 1
      break if page_count == 0
    end
  end
  entries
end
```