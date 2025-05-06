require "#{ENV['code_dir']}/lib/vapi"
require 'json'
require 'pry'

secrets_file = File.read(File.join(ENV['code_dir'], 'tests', 'secrets.json'))
secrets = JSON.parse(secrets_file, symbolize_names: true)

api_key = secrets[:apiKeys][:atx_demo_room]

api = Vapi.new(api_key)

cam_id = secrets[:devices][:demo_room_ot]

ot_data = api.get_ot_data(camera_id: cam_id)

pp ot_data

# binding.pry