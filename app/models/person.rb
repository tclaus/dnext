class Person < ApplicationRecord
  include Diaspora::Fields::Guid

  has_many :posts, foreign_key: :author_id, dependent: :destroy
  has_many :photos, foreign_key: :author_id, dependent: :destroy

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :pod, optional: true # on this pod, this attribute stays empty

  has_one :profile, dependent: :destroy
  delegate :first_name, :last_name, :full_name, :image_url, :tag_string, :bio, :location,
    :gender, :birthday, :formatted_birthday, :tags, :searchable,
    :public_details?, to: :profile
  accepts_nested_attributes_for :profile

  validate :owner_xor_pod
  validate :other_person_with_same_guid, on: :create
  validates :profile, presence: true
  validates :serialized_public_key, presence: true
  validates :diaspora_handle, uniqueness: true

  scope :remote, -> { where("people.owner_id IS NULL") }
  scope :local, -> { where("people.owner_id IS NOT NULL") }

  def avatar_small
    profile.image_url(size: :thumb_small)
  end

  # Set a default of an empty profile when a new Person record is instantiated.
  # Passing :profile => nil to Person.new will instantiate a person with no profile.
  # Calling Person.new with a block:
  #   Person.new do |p|
  #     p.profile = nil
  #   end
  # will not work!  The nil profile will be overridden with an empty one.
  def initialize(params = {})
    params = {} if params.nil?

    profile_set = params.has_key?(:profile) || params.has_key?("profile")
    params[:profile_attributes] = params.delete(:profile) if params.has_key?(:profile) && params[:profile].is_a?(Hash)
    super
    self.profile ||= Profile.new unless profile_set
  end

  def self.find_from_guid_or_username(params)
    p = if params[:id].present?
      Person.find_by(guid: params[:id])
    elsif params[:username].present? && u = User.find_by_username(params[:username])
      u.person
    end
    raise ActiveRecord::RecordNotFound unless p.present?
    p
  end

  def owner_xor_pod
    errors.add(:base, "Specify an owner or a pod, not both") unless owner.blank? ^ pod.blank?
  end

  def other_person_with_same_guid
    diaspora_id = Person.where(guid: guid)
      .where.not(diaspora_handle: diaspora_handle)
      .pluck(:diaspora_handle).first
    errors.add(:base, "Person with same GUID already exists: #{diaspora_id}") if diaspora_id
  end

  def name
    if self.profile.nil?
      # fix_profile #TODO: Implement fetch profile
    end
    @name ||= Person.name_from_attrs(self.profile.first_name, self.profile.last_name, diaspora_handle)
  end

  def self.name_from_attrs(first_name, last_name, diaspora_handle)
    first_name.blank? && last_name.blank? ? diaspora_handle : "#{first_name.to_s.strip} #{last_name.to_s.strip}".strip
  end
end
