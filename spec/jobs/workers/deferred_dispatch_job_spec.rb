# frozen_string_literal: true

require "rspec"

describe Workers::DeferredDispatchJob do
  context "when condition" do
    it "dont raises an exception when user wont exist" do
      expect {
        Workers::DeferredDispatchJob.new.perform(alice.id, "Comment", 0, {})
      }.not_to raise_error
    end
  end
end
