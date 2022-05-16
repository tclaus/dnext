# frozen_string_literal: true

module PostInteractionRender
  extend ActiveSupport::Concern

  def response_for_post(post)
    respond_to do |format|
      format.html { head :created }
      format.json do
        post_presenter = PostPresenter.new(post, current_user)
        render_json_response(post_presenter)
      end
    end
  end

  def render_json_response(post_presenter)
    render json:   {
      element_id:          "#{post_presenter.type.downcase}_#{post_presenter.id}",
      element_footer:      render_to_string(partial: "streams/stream_element_footer",
                                            locals:  {post: post_presenter},
                                            formats: [:html]),
      single_post_actions: render_to_string(partial: "posts/single_post_actions",
                                            locals:  {post: post_presenter},
                                            formats: [:html])
    },
           status: :created
  end
end
