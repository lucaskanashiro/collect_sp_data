class WeathersController < ApplicationController
  before_action :set_weather, only: [:show]

  # GET /weathers
  # GET /weathers.json
  def index
    @weathers = Weather.all
  end
end
