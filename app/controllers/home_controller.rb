# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    partial_dir = Rails.root.join("app", "views", "home")
    if user_signed_in?
      redirect_to public_stream_path # remove public stream and redirect to users stream path
    elsif partial_dir.join("_show.html.haml").exist? ||
        partial_dir.join("_show.html.erb").exist? ||
        partial_dir.join("_show.haml").exist?
      render :show
    elsif Role.admins.any?
      # If at least one admin exist, render default view.
      # This should be the normal view in correct setups.
      render :default
    else
      # If no admin role exist, its likely a new installation, so show the podmins view
      redirect_to podmin_path
    end
    # TODO: See original implementation
  end
end
