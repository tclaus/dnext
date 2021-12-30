class Reshare < Post
  belongs_to :root, class_name: "Post", foreign_key: :root_guid, primary_key: :guid, optional: true, counter_cache: true
  validate :root_must_be_public
  validates :root, presence: true, on: :create, if: proc { |reshare| reshare.author.local? }
  validates :root_guid, uniqueness: { scope: :author_id }, allow_nil: true
  delegate :author, to: :root, prefix: true

  def absolute_root
    @absolute_root ||= self
    @absolute_root = @absolute_root.root while @absolute_root.is_a? Reshare
    @absolute_root
  end

  private

  def root_must_be_public
    if self.root && !self.root.public
      errors[:base] << "Only posts which are public may be reshared."
      false
    end
  end
end
