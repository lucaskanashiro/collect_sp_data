require 'rubygems'
require 'json'
require 'yaml'
require 'mongo'
require 'rest-client'
require 'colorize'

project_path = "./"
project_path = ARGV[0] unless ARGV[0].nil?
load "#{project_path}/interscity_entity.rb"

config = YAML.load_file("#{project_path}/settings.yml")

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:olho_vivo]

token = `cat /tmp/.olho_vivo_api`
token = token.strip
url = "http://api.olhovivo.sptrans.com.br/v2.1/Login/Autenticar?token=#{token}"
response = RestClient.post(url, {})
auth = response.cookies['apiCredentials']

url = "http://api.olhovivo.sptrans.com.br/v2.1/Posicao"
response = RestClient.get(url, {
  cookies: {
    apiCredentials: auth
  }
})
body = JSON.parse(response)

body["l"].each do |line|
  line["vs"].each do |vehicle|
    doc = {
      prefix: vehicle["p"],
      lat: vehicle["py"],
      lon: vehicle["px"],
      timestamp: vehicle["ta"],
      display: line["c"],
      identifier_code: line["cl"],
      direction: line["sl"],
      display_origin: line["lt0"],
      display_destination: line["lt1"],
      vehicles_count: line["qv"]
    }

    collection.insert_one(doc)
  end
end
