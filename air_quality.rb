require 'rubygems'
require 'mechanize'
require 'mongo'
require 'yaml'
require 'time'
require 'rest-client'
require 'json'

project_path = "./"
project_path = ARGV[0] unless ARGV[0].nil?
load "#{project_path}/interscity_entity.rb"

config = YAML.load_file("#{project_path}settings.yml")

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:air_quality]

url_cetesb = "http://sistemasinter.cetesb.sp.gov.br/Ar/php/ar_resumo_hora.php"

agent = Mechanize.new
page = agent.get(url_cetesb)
page.encoding = "utf-8"
table = page.search("table tr td table.font01")[0]

class AirQuality < InterSCityEntity
  attr_accessor :region, :quality, :index, :polluting

  def initialize(params={})
    super
    self.status = "active"
    self.description = "#{self.region} air quality"
    self.registered = false
  end

  def capabilities
    ["air-quality", "polluting-index", "polluting"]
  end

  def normalized_registration_data
    {
      lat: -23.559616, # TODO: fakedata
      lon: -1.55, # TODO: fakedata
      description: self.description,
      capabilities: self.capabilities,
      status: "active"
    }
  end

  def normalized_update_data
    {
      air_quality: [{value: self.quality, timestamp: self.timestamp}],
      polluting_index: [{value: self.index, timestamp: self.timestamp}],
      polluting: [{value: self.polluting, timestamp: self.timestamp}]
    }
  end
end

resources = {}

table.element_children.each do |line|
	next if line.element_children.empty?

	data = line.element_children

	region = data[0].text
	index= data[2].text
	polluting = data[3].text

	img = data[1].element_children[0].attributes["src"].value

	quality = 'boa' if img.include? "quadro1.gif"
	quality = 'moderada' if img.include? "quadro2.gif"
	quality = 'ruim' if img.include? "quadro3.gif"
	quality = 'muito ruim' if img.include? "quadro4.gif"
	quality = 'péssima' if img.include? "quadro5.gif"

 timestamp = Time.now.getutc.to_s

	doc = {
    region: region,
    quality: quality,
    index: index,
    polluting: polluting,
    timestamp: timestamp
  }

	collection.insert_one(doc)

  if ENV["USE_INTERSCITY"] && ENV["INTERSCITY_ADAPTOR_HOST"]
    aq = AirQuality.new(doc)
    aq.register
    if aq.registered
      resources.update("#{aq.region}" => aq)
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
