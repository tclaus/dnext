require "rspec"

describe BasePresenter do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  context "when initialized with nil" do
    it "falls back to nil" do
      base_presenter = BasePresenter.new(nil)
      expect(base_presenter.anything).to be_nil
      expect {
        base_presenter.other_method
      }.not_to raise_exception
    end
  end

  it "calls methods on the wrapped object" do
    o = double(hello: "world")
    base_presenter = BasePresenter.new(o)
    expect(base_presenter.hello).to eql("world")
    expect(o).to have_received(:hello)
  end
end
