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
      element_id:               dom_id(post_presenter),
      element_footer:           render_to_string(partial: "streams/stream_element_footer",
                                                 locals:  {post: post_presenter},
                                                 formats: [:html]),
      single_post_actions:      render_to_string(partial: "posts/single_post_actions",
                                                 locals:  {post: post_presenter},
                                                 formats: [:html]),
      single_post_interactions: render_to_string(partial: "posts/single_post_interactions",
                                                 locals:  {post:    post_presenter,
                                                           formats: [:html]})

    },
           status: :created
  end

  private

  def dom_id(record)
    "#{post_to_model_name(record)}_#{record.id}"
  end

  def post_to_model_name(record)
    record.type.eql?("StatusMessage") ? "post" : "reshare"
  end
end
