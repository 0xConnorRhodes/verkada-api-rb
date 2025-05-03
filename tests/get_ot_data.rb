require "#{ENV['code_dir']}/vapi"
require 'json'

secrets_file = File.read(File.join(ENV['code_dir'], 'tests', 'secrets.json'))
secrets = JSON.parse(secrets_file, symbolize_names: true)

puts secrets

puts RUBY_VERSION

puts `pwd`