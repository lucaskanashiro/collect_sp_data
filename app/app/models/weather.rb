class Weather
  include Mongoid::Document
  store_in collection: "weather"
  field :neighborhood, type: String
  field :temperature, type: Integer
  field :thermal_sensation, type: Integer
  field :wind_speed, type: Integer
  field :humidity, type: String
  field :pressure, type: Float
end
