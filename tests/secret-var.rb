require 'json'
require 'pry'

puts ENV['HELLO']
secrets = JSON.parse(File.read('secrets.json'), symbolize_names: true)

puts secrets[:apiKeys][:rhodeshouse]

binding.pry