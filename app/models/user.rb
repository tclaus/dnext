# frozen_string_literal: true

class User < ApplicationRecord
  # attr_accessor :plain_otp_secret

  # encrypts :otp_secret

  # Include default devise modules.
  devise :registerable,
         :recoverable, :rememberable, :validatable, :trackable, :lockable,
         :lastseenable, lock_strategy: :none, unlock_strategy: :none

  devise :two_factor_authenticatable,
         :two_factor_backupable,
         otp_backup_code_length:     16,
         otp_number_of_backup_codes: 10

  has_one :person, inverse_of: :owner, foreign_key: :owner_id, dependent: :destroy

  has_many :tag_followings
  has_many :followed_tags, -> { order("tags.name") }, through: :tag_followings, source: :tag
  has_many :aspects, -> { order("order_id ASC") }
  has_many :aspect_memberships, through: :aspects
  has_many :contacts, dependent: :destroy
  has_many :contact_people, through: :contacts, source: :person
  has_many :blocks, dependent: :destroy
  has_many :ignored_people, through: :blocks, source: :person
  has_many :stream_languages, dependent: :destroy

  before_validation :strip_and_downcase_username
  before_validation :strip_and_downcase_email
  before_validation :set_current_language, on: :create
  before_destroy do
    raise "Never destroy users!"
  end

  validates :username, presence: true, uniqueness: true, format: {with: /\A[A-Za-z0-9_.-]+\z/},
            length: {maximum: 32}, exclusion: {in: AppConfig.settings.username_blacklist}

  validates :unconfirmed_email, format: {with: Devise.email_regexp, allow_blank: true}
  validates :language, inclusion: {in: AVAILABLE_LANGUAGE_CODES}

  validate :unconfirmed_email_quasiuniqueness

  validates :person, presence: true
  validates_associated :person
  validate :no_person_with_same_username

  serialize :hidden_shareables, Hash
  serialize :otp_backup_codes, Array

  delegate :guid, :public_key, :posts, :photos, :owns?, :image_url,
           :diaspora_handle, :name, :atom_url, :profile_url, :profile, :url,
           :first_name, :last_name, :full_name, :gender, :participations, to: :person
  delegate :id, :guid, to: :person, prefix: true

  def self.all_sharing_with_person(person)
    User.joins(:contacts).where(contacts: {person_id: person.id})
  end

  ### Helpers ############
  def self.build(opts={})
    user = User.new(opts.except(:person, :id))
    user.setup(opts)
    user
  end

  def self.find_or_build(opts={})
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
    return unless errors.empty?

    set_person(Person.new((opts[:person] || {}).except(:id)))
    generate_keys
    self
  end

  def otp_secret
    plain_otp_secret
  end

  def otp_secret=(val)
    self.plain_otp_secret = val
  end

  # Ensure that the unconfirmed email isn't already someone's email
  def unconfirmed_email_quasiuniqueness
    return unless User.exists?(["id != ? AND email = ?", id, unconfirmed_email])

    errors.add(:unconfirmed_email, I18n.t("errors.messages.taken"))
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
  end

  # Generate public/private keys for User and associated Person
  def generate_keys
    key_size = (Rails.env.test? ? 512 : 4096)

    self.serialized_private_key = OpenSSL::PKey::RSA.generate(key_size).to_s if serialized_private_key.blank?

    return unless person && person.serialized_public_key.blank?

    person.serialized_public_key = OpenSSL::PKey::RSA.new(serialized_private_key).public_key.to_s
  end

  def no_person_with_same_username
    diaspora_id = "#{username}#{User.diaspora_id_host}"
    if username_changed? && Person.exists?(diaspora_handle: diaspora_id)
      errors[:base] << "That username has already been taken"
    end
  rescue StandardError => e
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

  def share_with(person, aspect)
    UserServices::Connecting.new(self).share_with(person, aspect)
  end

  def disconnect(contact)
    UserServices::Connecting.new(self).disconnect(contact)
  end

  def disconnected_by(person)
    UserServices::Connecting.new(self).disconnected_by(person)
  end

  def comment!(target, text, opts={})
    UserServices::SocialActions.new(self).comment!(target, text, opts)
  end

  def participate!(target, opts={})
    UserServices::SocialActions.new(self).participate!(target, opts)
  end

  def participate_in_poll!(target, answer, opts={})
    UserServices::SocialActions.new(self).participate_in_poll!(target, answer, opts)
  end

  def like!(target, opts={})
    UserServices::SocialActions.new(self).like!(target, opts)
  end

  def like_comment!(target, opts={})
    UserServices::SocialActions.new(self).like_comment!(target, opts)
  end

  def reshare!(target, opts={})
    UserServices::SocialActions.new(self).reshare!(target, opts)
  end

  def find_visible_shareable_by_id(klass, id, opts={})
    UserServices::Querying.new(self).find_visible_shareable_by_id(klass, id, opts)
  end

  def visible_shareables(klass, opts={})
    UserServices::Querying.new(self).visible_shareables(klass, opts)
  end

  def posts_from(person, with_order: true)
    UserServices::Querying.new(self).posts_from(person, with_order: with_order)
  end

  def photos_from(_person, opts={})
    UserServices::Querying.new(self).photos_from(person, opts)
  end

  def contact_for(person)
    UserServices::Querying.new(self).contact_for(person)
  end

  def block_for(person)
    UserServices::Querying.new(self).block_for(person)
  end

  def aspects_with_shareable(base_class_name_or_class, shareable_id)
    UserServices::Querying.new(self).aspects_with_shareable(base_class_name_or_class, shareable_id)
  end

  def contact_for_person_id(person_id)
    UserServices::Querying.new(self).contact_for_person_id(person_id)
  end

  def people_in_aspects(requested_aspects, opts={})
    UserServices::Querying.new(self).people_in_aspects(requested_aspects, opts)
  end

  def aspects_with_person(person)
    UserServices::Querying.new(self).aspects_with_person(person)
  end

  def send_welcome_message
    return unless AppConfig.settings.welcome_message.enabled? && AppConfig.admins.account?

    sender_username = AppConfig.admins.account.get
    sender = User.find_by(username: sender_username)
    return if sender.nil?

    conversation = sender.build_conversation(
      participant_ids: [sender.person.id, person.id],
      subject:         AppConfig.settings.welcome_message.subject.get,
      message:         {text: AppConfig.settings.welcome_message.text.get % {username: username}}
    )

    Diaspora::Federation::Dispatcher.build(sender, conversation).dispatch if conversation.save
  end

  def encryption_key
    # This replaces the 2FA encryption key
    OpenSSL::PKey::RSA.new(serialized_private_key)
  end

  def hidden_shareables
    self[:hidden_shareables] ||= {}
  end

  def add_hidden_shareable(key, share_id, opts={})
    if hidden_shareables.has_key?(key)
      hidden_shareables[key] << share_id
    else
      hidden_shareables[key] = [share_id]
    end
    save unless opts[:batch]
    hidden_shareables
  end

  def remove_hidden_shareable(key, share_id)
    hidden_shareables[key].delete(share_id) if hidden_shareables.has_key?(key)
  end

  def is_shareable_hidden?(shareable)
    shareable_type = shareable.class.base_class.name
    if hidden_shareables.has_key?(shareable_type)
      hidden_shareables[shareable_type].include?(shareable.id.to_s)
    else
      false
    end
  end

  def toggle_hidden_shareable(share)
    share_id = share.id.to_s
    key = share.class.base_class.to_s
    if hidden_shareables.has_key?(key) && hidden_shareables[key].include?(share_id)
      remove_hidden_shareable(key, share_id)
      save
      false
    else
      add_hidden_shareable(key, share_id)
      save
      true
    end
  end

  def has_hidden_shareables_of_type?(t=Post)
    share_type = t.base_class.to_s
    hidden_shareables[share_type].present?
  end

  # Copy the method provided by Devise to be able to call it later
  # from a Sidekiq job
  alias send_reset_password_instructions! send_reset_password_instructions

  def send_reset_password_instructions
    Workers::ResetPasswordJob.perform_later(self)
  end

  def strip_and_downcase_username
    return if username.blank?

    username.strip!
    username.downcase!
  end

  def strip_and_downcase_email
    return if email.blank?

    email.strip!
    email.downcase!
  end

  def set_current_language
    self.language = I18n.locale.to_s if self.language.blank?
  end

  def sign_up
    save
  end

  def admin?
    Role.admin?(person)
  end

  def moderator?
    Role.moderator?(person)
  end

  def podmin?
    username == AppConfig.admins.account
  end

  ######## Posting ########
  def build_post(class_name, opts={})
    opts[:author] = person

    model_class = class_name.to_s.camelize.constantize
    model_class.diaspora_initialize(opts)
  end

  def dispatch_post(post, opts={})
    logger.info "user:#{id} dispatching #{post.class}:#{post.guid}"
    Diaspora::Federation::Dispatcher.defer_dispatch(self, post, opts)
  end

  def update_post(post, post_hash={})
    return unless owns? post

    post.update_attributes(post_hash)
    dispatch_post(post)
  end

  def add_to_streams(post, aspects_to_insert)
    aspects_to_insert.each do |aspect|
      aspect << post
    end
  end

  def aspects_from_ids(aspect_ids)
    if ["all", :all].include?(aspect_ids)
      aspects
    else
      aspects.where(id: aspect_ids).to_a
    end
  end

  def post_default_aspects
    if post_default_public
      ["public"]
    else
      aspects.where(post_default: true).to_a
    end
  end

  def update_post_default_aspects(post_default_aspect_ids)
    aspects.each do |aspect|
      enable = post_default_aspect_ids.include?(aspect.id.to_s)
      aspect.update_attribute(:post_default, enable)
    end
  end

  ######### Mailer #######################
  def mail(job, *args)
    return if job.blank?

    pref = job.to_s.gsub("Workers::Mail::", "").underscore
    job.perform_later(*args) if disable_mail == false && !user_preferences.exists?(email_type: pref)
  end

  def send_confirm_email
    return if unconfirmed_email.blank?

    Workers::Mail::ConfirmEmail.perform_later(id)
  end

  ######### Posts and Such ###############
  def retract(target)
    retraction = Diaspora::Federated::Retraction.for(target)
    retraction.defer_dispatch(self)
    retraction.perform
  end
end
