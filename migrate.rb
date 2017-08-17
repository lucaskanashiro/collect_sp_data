require 'mongo'

project_path = "./"
project_path = ARGV[0] unless ARGV[0].nil?

config = YAML.load_file("#{project_path}settings.yml")

db = Mongo::Client.new([ config["DATABASE_HOST"] ], :database => config["DATABASE_NAME"])
collection = db[:air_quality]

config = File.open("#{project_path}rm_sp").read

idxa=0
config.each_line do |rmsp|
    idxa += 1
    rmsp = rmsp.strip

    col = collection.find(region: rmsp)

    col.each_with_index do |a, idx|
        if idx > 3
            break
        end
        puts a.inspect
    end

    if idxa > 10
        break
    end

end
