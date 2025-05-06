require "#{ENV['code_dir']}/lib/vapi"
require 'json'
require 'pry'

secrets_file = File.read(File.join(ENV['code_dir'], 'tests', 'secrets.json'))
secrets = JSON.parse(secrets_file, symbolize_names: true)

api_key = secrets[:apiKeys][:sewr]
api = Vapi.new(api_key)

# get last hour of audit log events, force multiple pages
log = api.get_audit_logs(start_time: (Time.now - 60*60).to_i, page_size: 1, page_count: 5)

pp log