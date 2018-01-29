class WeathersController < ApplicationController
  # GET /weathers
  # GET /weathers.json
  def index
    @weathers = Weather.paginate(:page => params[:page], :per_page => 50)
  end
end
