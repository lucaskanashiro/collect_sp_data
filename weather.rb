require 'rubygems'
require 'mechanize'

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

	large_temperature = page.at('#detail-now .forecast .info .temp .large-temp').text
	large_temperature = large_temperature.gsub!(/[^0-9]/, '').to_i

	small_temperature = page.at('#detail-now .forecast .info .temp .small-temp').text
	small_temperature = small_temperature.gsub!(/[^0-9]/, '').to_i

	stats = page.at('#detail-now .more-info .stats').text.strip
	stats = stats.gsub!(/\:/, '')
	stats = stats.split(/\s/).reject(&:empty?)

	humidity_index = stats.index('Umidade') + 1
	pressure_index = stats.index('Pressão') + 1

	wind_speed = stats[0].to_i
	humidity = stats[humidity_index]
	pressure = stats[pressure_index].to_f

	puts '==========================================='
	puts neighborhood
	puts "Large Temperature: #{large_temperature}"
	puts "Small Temperature: #{small_temperature}"
	puts "Wind Speed: #{wind_speed}"
	puts "Humidity: #{humidity}"
	puts "Pressure: #{pressure}"
	puts '==========================================='
end
