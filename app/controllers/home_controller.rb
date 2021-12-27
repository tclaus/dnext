class HomeController < ApplicationController
  def show
    redirect_to streams_public_path
  end
end
