require "#{ENV['code_dir']}/lib/vapi"
require 'json'
require 'pry'

secrets_file = File.read(File.join(ENV['code_dir'], 'tests', 'secrets.json'))
secrets = JSON.parse(secrets_file, symbolize_names: true)

api_key = secrets[:apiKeys][:atx_demo_room]

api = Vapi.new(api_key)

cams = api.get_camera_data

# pp cams

binding.pry