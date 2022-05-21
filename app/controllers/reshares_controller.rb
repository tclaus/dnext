# frozen_string_literal: true

class ResharesController < ApplicationController
  include PostInteractionRender

  before_action :authenticate_user!, except: :index
  respond_to :json

  def new
    @reshare = Reshare.new(root_guid: params[:root_guid])
  end

  def create
    @reshare = reshare_service.create(param_root_guid, param_text)
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
    respond_to do |format|
      format.turbo_stream { flash.now[:error] = t("reshares.create.error") }
      format.json { render  status: :unprocessable_entity }
    end
  else
    post_presenter = PostPresenter.new(@reshare.root, current_user)
    render_json_response(post_presenter)
  end

  def index
    render json: reshare_service.find_for_post(params[:post_id])
                                .includes(author: :profile)
                                .as_api_response(:backbone)
  end

  private

  def param_text
    params[:reshare][:text]
  end

  def param_root_guid
    # in recent implementation the guid was sent by javascript
    # in dnext ist send by a form.
    # This is for compatibility reasons
    params[:root_guid] || params[:reshare][:root_guid]
  end

  def reshare_service
    @reshare_service ||= ReshareService.new(current_user)
  end
end
