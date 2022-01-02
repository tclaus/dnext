class ApplicationController < ActionController::Base
  def authenticate_user!
    log("Auth User")
    # Keep cool !
    # Remove when devise is implemented
  end

  # Max time for stream view
  def max_time
    params[:max_time] ? Time.at(params[:max_time].to_i) : Time.now + 1.second
  end
end
