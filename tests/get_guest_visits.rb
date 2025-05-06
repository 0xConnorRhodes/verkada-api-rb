require "#{ENV['code_dir']}/lib/vapi"
require 'json'
require 'pry'

secrets_file = File.read(File.join(ENV['code_dir'], 'tests', 'secrets.json'))
secrets = JSON.parse(secrets_file, symbolize_names: true)

api_key = secrets[:apiKeys][:atx_demo_room]

api = Vapi.new(api_key)

guest_visits = api.get_guest_visits(
  site_id: ARGV[0], # pass site ID as cli arg
  end_time: Time.now.to_i,
  start_time: Time.now.to_i - 86400 * 100
)

pp guest_visits

# binding.pry
