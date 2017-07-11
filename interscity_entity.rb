require 'colorize'
require 'json'
require 'mongo'

class InterSCityEntity
  attr_accessor :status, :description, :lat, :lon,
    :uuid, :timestamp, :info, :registered

  def initialize(params={})
    self.status = "active"
    self.registered = false
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def capabilities
    puts "WARNING: You didn't override the capabilities of this entity.".yellow
    []
  end

  def register
    url = ENV["INTERSCITY_ADAPTOR_HOST"] + "/components"

    doc = normalized_registration_data

    begin
      response = RestClient.post(url, {data: doc})
      response = JSON.parse(response)
      self.uuid = response["data"]["uuid"]
      self.registered = true
      puts "Resource #{self.uuid} #{'registered'.green}"
    rescue RestClient::Exception => e
      puts "ERROR: Could not register resource. Description: #{e}".red
    end
  end

  def normalized_update_data
    raise "You should override #normalized_update_data"
  end

  def normalized_registration_data
    raise "You should override #normalized_registration_data"
  end

  def send_data
    doc = normalized_update_data

    url = ENV["INTERSCITY_ADAPTOR_HOST"] + "/components/#{self.uuid}/data"

    begin
      response = RestClient.post(url, {data: doc})
      puts "Resource #{self.uuid} #{'updated'.blue}"
    rescue RestClient::Exception => e
      puts "ERROR: Could not send data from resource. Description: #{e.response}".red
    end
  end
end
