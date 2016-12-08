require 'rubygems'
require 'mechanize'
require 'mongo'
require 'yaml'

config = YAML.load_file('settings.yml')

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:weather]

url_accuweather = "http://www.accuweather.com/pt/br/brazil-weather"
city = "São Paulo"
country = "BR"

agent = Mechanize.new
config = File.open('neighborhood').read

config.each_line do |neighborhood|
	neighborhood = neighborhood.strip

	weather = agent.get(url_accuweather)

	form = weather.forms[1]
	form['s'] = "#{neighborhood}, #{city}"
	response = form.submit

	if !response.at('.results-list h3').nil?
		if response.at('.results-list h3').text == "Múltiplos locais encontrados:"
			location = response.link_with(text: "#{neighborhood}, #{city}, #{country} ")
			response = location.click
		end
	end

	link = response.link_with(text: 'Situação meteorológica atual')
	page = link.click

	temperature = page.at('#detail-now .forecast .info .temp .large-temp').text
	temperature = temperature.gsub!(/[^0-9]/, '').to_i

	thermal_sensation = page.at('#detail-now .forecast .info .temp .small-temp').text
	thermal_sensation = thermal_sensation.gsub!(/[^0-9]/, '').to_i

	stats = page.at('#detail-now .more-info .stats').text.strip
	stats = stats.gsub!(/\:/, '')
	stats = stats.split(/\s/).reject(&:empty?)

	humidity_index = stats.index('Umidade') + 1
	pressure_index = stats.index('Pressão') + 1

	wind_speed = stats[0].to_i
	humidity = stats[humidity_index]
	pressure = stats[pressure_index].to_f

	doc = { neighborhood: neighborhood,
          temperature: temperature,
          thermal_sensation: thermal_sensation,
          wind_speed: wind_speed,
          humidity: humidity,
          pressure: pressure }

	collection.insert_one(doc)
end
