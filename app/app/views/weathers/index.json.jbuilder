json.array!(@weathers) do |weather|
  json.extract! weather, :id, :neighborhood, :temperature, :thermal_sensation, :wind_speed, :humidity, :pressure
  json.url weather_url(weather, format: :json)
end
