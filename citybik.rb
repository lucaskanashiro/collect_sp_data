require 'rubygems'
require 'json'
require 'yaml'
require 'mongo'
require 'rest-client'
require 'colorize'

project_path = "./"
project_path = ARGV[0] unless ARGV[0].nil?

config = YAML.load_file("#{project_path}settings.yml")

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:bike_stations]

class BikeStation
  attr_accessor :status, :description, :region, :address, :lat, :lon,
    :uuid, :timestamp, :info, :registered, :free_bikes, :slots

  def initialize(params={})
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
    self.registered = false
    self.description = "#{self.info} bike station, from #{self.address}"
  end

  def self.normalize(raw)
    {
      empty_slots: raw["empty_slots"],
      address: raw["extra"]["address"],
      free_bikes: raw["free_bikes"],
      external_uid: raw["id"],
      lat: raw["latitude"],
      lon: raw["longitude"],
      slots: raw["extra"]["slots"],
      info: raw["name"],
      status: raw["extra"]["status"]
    }
  end

  def capabilities
    ["slots", "free_bikes", "address", "external_uid"]
  end

  def register_resource
    url = ENV["INTERSCITY_ADAPTOR_HOST"] + "/components"

    doc = {
      lat: self.lat,
      lon: self.lon,
      description: self.description,
      capabilities: self.capabilities,
      status: self.status
    }

    begin
      response = RestClient.post(url, {data: doc})
      response = JSON.parse(response)
      self.uuid = response["data"]["uuid"]
      self.registered = true
      puts "Resource #{self.uuid} #{'registered'.green}"
    rescue RestClient::Exception => e
      puts "ERROR: Could not register resource. Description: #{e}".red
    end
  end

  def send_data
    url = ENV["INTERSCITY_ADAPTOR_HOST"] + "/components/#{self.uuid}/data"

    doc = {
      free_bikes: [{value: self.free_bikes, timestamp: self.timestamp}],
      slots: [{value: self.slots, timestamp: self.timestamp}]
    }

    begin
      response = RestClient.post(url, {data: doc})
      puts "Resource #{self.uuid} #{'updated'.blue}"
    rescue RestClient::Exception => e
      puts "ERROR: Could not send data from resource. Description: #{e.response}".red
    end
  end
end

# add new network_ids from `https://api.citybik.es/v2/networks`
networks_ids = ["bikesantos"]
resources = {}
base_url = "https://api.citybik.es/v2/"

networks_ids.each do |nw|
  url = base_url + "/networks/#{nw}"
  response = RestClient.get(url)
  network = JSON.parse(response)["network"]

  collection.insert_one(network)
  if ENV["USE_INTERSCITY"] && ENV["INTERSCITY_ADAPTOR_HOST"]
    network["stations"].each do |sta|
      normalized_attrs = BikeStation.normalize(sta)
      bs = BikeStation.new(normalized_attrs)
      bs.register_resource
      if bs.registered
        resources.update("#{bs.uuid}" => bs)
      end
    end
  else
    puts ">>> InterSCity configuration not found <<<"
  end
end

if ENV["USE_INTERSCITY"] && ENV["INTERSCITY_ADAPTOR_HOST"]
  resources.each do |key, entity|
    entity.send_data
  end
end
