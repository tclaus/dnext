class ApplicationController < ActionController::Base

  # Max time for stream view
  def max_time
    params[:max_time] ? Time.at(params[:max_time].to_i) : Time.now + 1.second
  end

end
