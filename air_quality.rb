require 'rubygems'
require 'mechanize'
require 'mongo'
require 'yaml'
require 'time'

project_path = "./"
project_path = ARGV[0] unless ARGV[0].nil?

config = YAML.load_file("#{project_path}settings.yml")

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:air_quality]

url_cetesb = "http://sistemasinter.cetesb.sp.gov.br/Ar/php/ar_resumo_hora.php"

agent = Mechanize.new
page = agent.get(url_cetesb)
table = page.search("table tr td table.font01")[0]

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

	doc = { region: region,
         quality: quality,
         index: index,
         polluting: polluting,
         timestamp: timestamp }

	collection.insert_one(doc)
end
