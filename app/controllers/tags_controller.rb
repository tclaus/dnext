# frozen_string_literal: true

class TagsController < ApplicationController
  layout "with_header"
  helper_method :tag_followed?
  include Pagy::Backend

  respond_to :html, only: [:show]
  respond_to :json, only: %i[index show]

  def index
    if params[:q] && params[:q].length > 1
      params[:q].delete!("#")
      @tags = ActsAsTaggableOn::Tag.autocomplete(params[:q]).limit(params[:limit] - 1)
      prep_tags_for_javascript

      respond_to do |format|
        format.json { render(json: @tags.to_json, status: :ok) }
      end
    else
      respond_to do |format|
        format.json { head :unprocessable_entity }
        format.html { redirect_to tag_path("partytimeexcellent") }
      end
    end
  end

  def show
    redirect_to(action: :show, name: downcase_tag_name) && return if tag_has_capitals?

    @tag_stream_presenter = TagStreamPresenter.new(tag_stream)
    @pagy, @stream = pagy(tag_stream.stream_posts)
    @tagged_people_pagy, @tagged_people_stream = pagy(tag_stream.tagged_people)

    respond_to do |format|
      format.html { render "tags/show" }
      format.json do
        render json: {
          entries:    render_to_string(partial: "streams/stream_elements",
                                       formats: [:html]),
          pagination: view_context.pagy_nav(@pagy)
        }
      end
    end
  end

  private

  def tag_stream
    @tag_stream ||= Stream::Tag.new(current_user, params[:name])
  end

  def tag_followed?
    TagFollowing.user_is_following?(current_user, params[:name])
  end

  def tag_has_capitals?
    mb_tag = params[:name].mb_chars
    mb_tag.downcase != mb_tag
  end

  def downcase_tag_name
    params[:name].mb_chars.downcase.to_s
  end

  def prep_tags_for_javascript
    @tags = @tags.map {|tag|
      {name: ("#" + tag.name)}
    }

    @tags << {name: ("#" + params[:q])}
    @tags.uniq!
  end
end
