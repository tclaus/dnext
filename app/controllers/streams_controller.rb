# frozen_string_literal: true

class StreamsController < ApplicationController
  before_action :authenticate_user!, except: :public
  # before_action :save_selected_aspects, :only => :aspects
  layout "with_header"

  include Pagy::Backend

  def public
    stream_responder(Stream::Public)
  end

  def stream
    multi
  end

  def multi
    # will show all following users with all followed tags
    stream_responder(Stream::Multi)
  end

  def local_public; end

  private

  def stream_responder(stream_builder=nil)
    @stream_builder_object = stream_builder.new(current_user)
    @pagy, @stream = pagy_countless(@stream_builder_object.stream_posts)
    respond_to do |format|
      format.html { render "streams/main_stream" }
      format.json do
        render json: {
          entries:    render_to_string(partial: "stream_elements",
                                       formats: [:html]),
          pagination: countless_stream_next_tag(@pagy)
        }
      end
    end
  end
end
