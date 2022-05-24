# frozen_string_literal: true

require "rails_helper"

describe "Post Interaction Render Concern", type: :controller do
  before do
    class RendererController < ApplicationController
      include PostInteractionRender
    end
    sign_in bob
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
      post_presenter = PostPresenter.new(post, bob)
      json = render_controller.render_json_response(post_presenter)
    end
  end
end
