require 'rubygems'
require 'mechanize'
require 'mongo'
require 'yaml'
require 'time'
require 'rest-client'

project_path = "./"
project_path = ARGV[0] unless ARGV[0].nil?
load "#{project_path}/interscity_entity.rb"

config = YAML.load_file("#{project_path}settings.yml")

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:weather]

url_accuweather = "http://www.accuweather.com/pt/br/brazil-weather"
city = "São Paulo"
country = "BR"

agent = Mechanize.new
config = File.open("#{project_path}neighborhood").read

class Weather < InterSCityEntity
  attr_accessor :temperature, :thermal_sensation, :wind_speed,
    :humidity, :pressure, :neighborhood, :address

  def initialize(params={})
    super
    self.description = "weather from #{self.address}"
  end

  def normalized_update_data
    {
      temperature: [{value: self.temperature, timestamp: self.timestamp}],
      thermal_sensation: [{value: self.thermal_sensation, timestamp: self.timestamp}],
      wind_speed: [{value: self.wind_speed, timestamp: self.timestamp}],
      humidity: [{value: self.humidity, timestamp: self.timestamp}],
      pressure: [{value: self.pressure, timestamp: self.timestamp}],
      neighborhood: [{value: self.neighborhood, timestamp: self.timestamp}]
    }
  end

  def normalized_registration_data
    {
      lat: -1, # TODO => fakedata
      lon: -1, # TODO => fakedata
      description: self.description,
      capabilities: self.capabilities,
      status: self.status
    }
  end

  def capabilities
    ["temperature", "thermal_sensation", "wind_speed", "humidity",
     "pressure", "neighborhood"]
  end
end

resources = {}

config.each_line do |neighborhood|
	neighborhood = neighborhood.strip

	weather = agent.get(url_accuweather)

	form = weather.forms[1]
	form['s'] = "#{neighborhood}, #{city}"
	response = form.submit

	if !response.at('.results-list h3').nil?
		if response.at('.results-list h3').text == "Vários locais encontrados:"
			location = response.link_with(text: "#{neighborhood}, #{city}, #{country} ")
			response = location.click
		end
	end

	link = response.link_with(text: 'Tempo atual')
	page = link.click

	temperature = page.at('#detail-now .forecast .info .temp .large-temp').text
	temperature = temperature.gsub!(/[^0-9]/, '').to_i

	thermal_sensation = page.at('#detail-now .forecast .info .temp .small-temp').text
	thermal_sensation = thermal_sensation.gsub!(/[^0-9]/, '').to_i

	stats = page.at('#detail-now .more-info .stats').text.strip
	stats = stats.gsub!(/\:/, '')
	stats = stats.split(/\s/).reject(&:empty?)

	humidity_index = stats.index('Humidade') + 1
  uv_index = stats.index('UV') + 1
	pressure_index = stats.index('Pressão') + 1
  cloud_coverage_index = stats.index('nuvens') + 1

	wind_speed = stats[3].to_i
	humidity = stats[humidity_index]
	pressure = stats[pressure_index].to_f
  uv = stats[uv_index].to_i
  cloud_coverage = stats[cloud_coverage_index]

  timestamp = Time.now.getutc.to_s

	doc = { neighborhood: neighborhood,
         temperature: temperature,
         thermal_sensation: thermal_sensation,
         wind_speed: wind_speed,
         humidity: humidity,
         pressure: pressure,
         uv: uv,
         cloud_coverage: cloud_coverage,
         timestamp: timestamp }

  if ENV["USE_INTERSCITY"] && ENV["INTERSCITY_ADAPTOR_HOST"]
    wt = Weather.new(doc)
    wt.register
    if wt.registered
      resources.update("#{wt.uuid}" => wt)
    end
  end

	collection.insert_one(doc)
end

if ENV["USE_INTERSCITY"] && ENV["INTERSCITY_ADAPTOR_HOST"]
  resources.each do |key, entity|
    entity.send_data
  end
end
