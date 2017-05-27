require 'rubygems'
require 'mechanize'
require 'mongo'
require 'yaml'
require 'time'
require 'rest-client'
require 'json'

project_path = "./"
project_path = ARGV[0] unless ARGV[0].nil?

config = YAML.load_file("#{project_path}settings.yml")

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:air_quality]

url_cetesb = "http://sistemasinter.cetesb.sp.gov.br/Ar/php/ar_resumo_hora.php"

agent = Mechanize.new
page = agent.get(url_cetesb)
page.encoding = "utf-8"
table = page.search("table tr td table.font01")[0]

class AirQuality
  attr_accessor :status, :description, :registered, :region, :quality,
    :uuid, :timestamp, :index, :polluting
  def initialize(params={})
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
    self.status = "active"
    self.description = "#{self.region} air quality"
    self.registered = false
  end

  def capabilities
    ["air-quality", "polluting-index", "polluting"]
  end

  def register_resource
    url = ENV["INTERSCITY_ADAPTOR_HOST"] + "/components"

    doc = {
      lat: -23.559616,
      lon: -1.55,
      description: self.description,
      capabilities: self.capabilities,
      status: "active",
    }

    begin
      response = RestClient.post(url, {data: doc})
      response = JSON.parse(response)
      self.uuid = response["data"]["uuid"]
      self.registered = true
    rescue RestClient::Exception => e
      puts "ERROR: Could not register resource. Description: #{e}"
    end
  end

  def send_data
    url = ENV["INTERSCITY_ADAPTOR_HOST"] + "/components/#{self.uuid}/data"

    doc = {
      air_quality: [{value: self.quality, timestamp: self.timestamp}],
      polluting_index: [{value: self.index, timestamp: self.timestamp}],
      polluting: [{value: self.polluting, timestamp: self.timestamp}]
    }

    begin
      response = RestClient.post(url, {data: doc})
      self.registered = true
    rescue RestClient::Exception => e
      puts "ERROR: Could not send data from resource. Description: #{e.response}"
    end
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
    aq.register_resource
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
