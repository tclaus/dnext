class StreamsController < ApplicationController
  def public
    stream_responder(Stream::Public)
  end

  private

  def stream_responder(stream_klass = nil)
    @stream ||= stream_klass.new(current_user, max_time: max_time) if stream_klass.present?

    respond_with do |format|
      format.html { render 'streams/main_stream' }
      format.mobile { render 'streams/main_stream' }
      format.json do
        render json: @stream.stream_posts.map { |p|
                       LastThreeCommentsDecorator.new(PostPresenter.new(p, current_user))
                     }
      end
    end
  end

  def save_selected_aspects
    return unless params[:a_ids].present?

    session[:a_ids] = params[:a_ids]
  end
end
