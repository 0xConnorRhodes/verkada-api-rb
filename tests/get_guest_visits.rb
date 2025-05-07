require "#{ENV['code_dir']}/lib/vapi"
require 'json'
require 'pry'

secrets_file = File.read(File.join(ENV['code_dir'], 'tests', 'secrets.json'))
secrets = JSON.parse(secrets_file, symbolize_names: true)

api_key = secrets[:apiKeys][:guest_k12]

api = Vapi.new(api_key)

guest_visits = api.get_guest_visits(
  site_id: secrets[:orgInfo][:guest_k12_site],
  end_time: Time.now.to_i,
  start_time: Time.now.to_i - (86400 * 30) # pull the last 30 days of Guest logs
)

pp guest_visits

# binding.pry
