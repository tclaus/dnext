# frozen_string_literal: true

shared_examples_for "it is a stream" do
  context "required methods for display" do
    it "#title" do
      expect(@stream.title).not_to be_nil
    end

    it "#posts" do
      expect(@stream.posts).not_to be_nil
    end
  end
end
