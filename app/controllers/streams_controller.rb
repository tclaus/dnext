class StreamsController < ApplicationController
  include Pagy::Backend

  def public
    stream_responder(Stream::Public)
  end

  def local_public; end

  private

  def stream_responder(stream_builder = nil)
    @stream_builder_object = stream_builder.new
    @pagy, @stream = pagy(@stream_builder_object.stream_posts)

    respond_to do |format|
      format.html { render 'streams/main_stream' }
      format.json do
        render json: {
          entries: render_to_string(partial: 'stream_elements',
                                    formats: [:html]),
          pagination: view_context.pagy_nav(@pagy)
        }
      end
    end
  end
end
