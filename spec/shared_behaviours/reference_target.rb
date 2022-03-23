# frozen_string_literal: true

shared_examples_for "a reference target" do
  let!(:target) { FactoryBot.create(described_class.to_s.underscore.to_sym) }
  let!(:reference) { FactoryBot.create(:reference, target: target) }

  describe "referenced_by" do
    it "returns the references where the target is referenced" do
      expect(target.referenced_by).to match_array([reference])
    end

    it "destroys the reference when the target is destroyed" do
      target.destroy
      expect(Reference.where(id: reference.id)).not_to exist
    end
  end
end
