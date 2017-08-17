require 'mongo'

project_path = "./"
project_path = ARGV[0] unless ARGV[0].nil?

config = YAML.load_file("#{project_path}settings.yml")

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:air_quality]

config = File.open("#{project_path}rm_sp").read

config.each_line do |rmsp, idx|
    rmsp = rmsp.strip

    if idx > 10
        break
    end

    puts collection.find(region: rmsp)
end
