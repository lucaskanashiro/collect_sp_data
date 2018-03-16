class BusesController < ApplicationController
  def index
    @buses = Bus.paginate(:page => params[:page], :per_page => 50)
  end
end
