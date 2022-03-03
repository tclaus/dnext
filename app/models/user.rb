# frozen_string_literal: true

class User < ApplicationRecord
  encrypts :otp_secret

  # Include default devise modules. Others available are:
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable, :lockable,
         :lastseenable, lock_strategy: :none, unlock_strategy: :none

  has_one :person, inverse_of: :owner, foreign_key: :owner_id

  has_many :tag_followings
  has_many :followed_tags, -> { order("tags.name") }, through: :tag_followings, source: ActsAsTaggableOn::Tag
  has_many :aspects, -> { order("order_id ASC") }
  has_many :aspect_memberships, through: :aspects
  has_many :contacts
  has_many :contact_people, through: :contacts, source: :person
  has_many :blocks
  has_many :ignored_people, through: :blocks, source: :person

  before_validation :strip_and_downcase_username
  before_validation :strip_and_downcase_email
  before_validation :set_current_language, on: :create

  before_destroy do
    raise "Never destroy users!"
  end

  validates :username, presence: true, uniqueness: true, format: { with: /\A[A-Za-z0-9_.\-]+\z/ },
            length: { maximum: 32 }, exclusion: { in: AppConfig.settings.username_blacklist }

  validates :unconfirmed_email, format: { with: Devise.email_regexp, allow_blank: true }
  validates :language, inclusion: { in: AVAILABLE_LANGUAGE_CODES }

  validate :unconfirmed_email_quasiuniqueness

  validates :person, presence: true
  validates_associated :person
  validate :no_person_with_same_username

  delegate :guid, :public_key, :posts, :photos, :owns?, :image_url,
           :diaspora_handle, :name, :atom_url, :profile_url, :profile, :url,
           :first_name, :last_name, :full_name, :gender, :participations, to: :person
  delegate :id, :guid, to: :person, prefix: true

  def self.all_sharing_with_person(person)
    User.joins(:contacts).where(contacts: { person_id: person.id })
  end

  def basic_profile_present?
    tag_followings.any? || profile[:image_url]
  end

  ### Helpers ############
  def self.build(opts = {})
    user = User.new(opts.except(:person, :id))
    user.setup(opts)
    user
  end

  def self.find_or_build(opts = {})
    user = User.find_by(username: opts[:username])
    user ||= User.build(opts)
    user
  end

  def setup(opts)
    self.username = opts[:username]
    self.email = opts[:email]
    self.language = opts[:language]
    self.language ||= I18n.locale.to_s
    self.color_theme = opts[:color_theme]
    self.color_theme ||= AppConfig.settings.default_color_theme
    valid?
    errors = self.errors
    errors.delete :person
    return if errors.size > 0

    set_person(Person.new((opts[:person] || {}).except(:id)))
    generate_keys
    self
  end

  # Ensure that the unconfirmed email isn't already someone's email
  def unconfirmed_email_quasiuniqueness
    if User.exists?(["id != ? AND email = ?", id, unconfirmed_email])
      errors.add(:unconfirmed_email, I18n.t("errors.messages.taken"))
    end
  end

  def guard_unconfirmed_email
    self.unconfirmed_email = nil if unconfirmed_email.blank? || unconfirmed_email == email

    return unless will_save_change_to_unconfirmed_email?

    self.confirm_email_token = unconfirmed_email ? SecureRandom.hex(15) : nil
  end

  # Whenever email is set, clear all unconfirmed emails which match
  def remove_invalid_unconfirmed_emails
    return unless saved_change_to_email?
    User.where(unconfirmed_email: email).update_all(unconfirmed_email: nil, confirm_email_token: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end

  # Generate public/private keys for User and associated Person
  def generate_keys
    key_size = (Rails.env == "test" ? 512 : 4096)

    self.serialized_private_key = OpenSSL::PKey::RSA.generate(key_size).to_s if serialized_private_key.blank?

    if person && person.serialized_public_key.blank?
      person.serialized_public_key = OpenSSL::PKey::RSA.new(serialized_private_key).public_key.to_s
    end
  end

  def no_person_with_same_username
    diaspora_id = "#{username}#{User.diaspora_id_host}"
    if username_changed? && Person.exists?(diaspora_handle: diaspora_id)
      errors[:base] << "That username has already been taken"
    end
  rescue => e
    logger.error e
  end

  def set_person(person)
    person.diaspora_handle = "#{username}#{User.diaspora_id_host}"
    self.person = person
  end

  def self.diaspora_id_host
    "@#{AppConfig.bare_pod_uri}"
  end

  def seed_aspects
    aspects.create(name: I18n.t("aspects.seed.family"))
    aspects.create(name: I18n.t("aspects.seed.friends"))
    aspects.create(name: I18n.t("aspects.seed.work"))
    aq = aspects.create(name: I18n.t("aspects.seed.acquaintances"))

    if AppConfig.settings.autofollow_on_join?
      begin
        default_account = Person.find_or_fetch_by_identifier(AppConfig.settings.autofollow_on_join_user)
        share_with(default_account, aq)
      rescue DiasporaFederation::Discovery::DiscoveryError
        logger.warn "Error auto-sharing with #{AppConfig.settings.autofollow_on_join_user}
                     fix autofollow_on_join_user in configuration."
      end
    end
    aq
  end

  def send_welcome_message
    return unless AppConfig.settings.welcome_message.enabled? && AppConfig.admins.account?
    sender_username = AppConfig.admins.account.get
    sender = User.find_by(username: sender_username)
    return if sender.nil?
    conversation = sender.build_conversation(
      participant_ids: [sender.person.id, person.id],
      subject: AppConfig.settings.welcome_message.subject.get,
      message: { text: AppConfig.settings.welcome_message.text.get % { username: username } }
    )

    Diaspora::Federation::Dispatcher.build(sender, conversation).dispatch if conversation.save
  end

  def encryption_key
    OpenSSL::PKey::RSA.new(serialized_private_key)
  end

  def encryption_key
    OpenSSL::PKey::RSA.new(serialized_private_key)
  end

  # Copy the method provided by Devise to be able to call it later
  # from a Sidekiq job
  alias_method :send_reset_password_instructions!, :send_reset_password_instructions

  def send_reset_password_instructions
    ResetPasswordJob.perform_later(self)
  end

  def strip_and_downcase_username
    if username.present?
      username.strip!
      username.downcase!
    end
  end

  def strip_and_downcase_email
    if email.present?
      email.strip!
      email.downcase!
    end
  end

  def set_current_language
    self.language = I18n.locale.to_s if self.language.blank?
  end

  def sign_up
    save
  end

  def admin?
    false
  end

  def moderator?
    false
  end

  ######### Mailer #######################
  def mail(job, *args)
    return unless job.present?
    pref = job.to_s.gsub("Workers::Mail::", "").underscore
    if disable_mail == false && !user_preferences.exists?(email_type: pref)
      job.perform_async(*args)
    end
  end

  def send_confirm_email
    return if unconfirmed_email.blank?
    Workers::Mail::ConfirmEmail.perform_async(id)
  end
end
