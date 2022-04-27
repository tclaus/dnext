require "rspec"

describe DeferredDispatchJob, type: :job do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  context "when condition" do
    it "dont raises an exception when user wont exist" do
      expect {
        DeferredDispatchJob.new.perform(alice.id, "Comment", 0, {})
      }.to_not raise_error
    end
  end
end
