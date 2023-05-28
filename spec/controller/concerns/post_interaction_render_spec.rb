# frozen_string_literal: true

describe "Post Interaction Render Concern", type: :controller do
  before do
    class RendererController < ApplicationController
      include PostInteractionRender
    end

    @user = FactoryBot.create(:user)
    sign_in @user
  end

  let(:render_controller) { RendererController.new }

  after do
    Object.send :remove_const, :RendererController
  end

  describe "#response_for_post" do
    it "Renders HTML Created status" do
      # How To Test a controller concern?
    end
  end

  describe "render_json_response" do
    it "returns a json" do
      post = FactoryBot.create(:status_message)
      post_presenter = PostPresenter.new(post, @user)
      json = render_controller.render_json_response(post_presenter)
    end
  end
end
