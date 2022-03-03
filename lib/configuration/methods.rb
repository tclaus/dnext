# frozen_string_literal: true

module Configuration
  KNOWN_SERVICES = %i[twitter tumblr wordpress].freeze

  module Methods
    def pod_uri
      return @pod_uri.dup unless @pod_uri.nil?

      url = environment.url.get

      begin
        @pod_uri = Addressable::URI.heuristic_parse(url)
      rescue
        puts "WARNING: pod url #{url} is not a legal URI"
      end

      @pod_uri.scheme = "https" if Rails.env.production?
      @pod_uri.path = "/"

      @pod_uri.dup
    end

    # @param path [String]
    # @return [String]
    def url_to(path)
      pod_uri.tap { |uri| uri.path = path }.to_s
    end

    def bare_pod_uri
      pod_uri.authority.gsub("www.", "")
    end

    def configured_services
      return @configured_services unless @configured_services.nil?

      @configured_services = []
      KNOWN_SERVICES.each do |service|
        @configured_services << service if services.send(service).enable?
      end

      @configured_services
    end

    attr_writer :configured_services

    def show_service?(service, user)
      return false unless self["services.#{service}.enable"]

      # Return true only if 'authorized' is true or equal to users username
      (user && self["services.#{service}.authorized"] == user.username) ||
        self["services.#{service}.authorized"] == true
    end

    def local_posts_stream?(user)
      return true if settings.enable_local_posts_stream == "admins" &&
        user.admin?
      return true if settings.enable_local_posts_stream == "moderators" &&
        user.moderator?

      settings.enable_local_posts_stream == "everyone"
    end

    # Generates a new token file if non exists
    def secret_token
      token_file = Rails.root.join("config", "initializers", "secret_token.rb")
      system "bin/rake generate:secret_token" unless File.exist? token_file
      require token_file
      Diaspora::Application.config.secret_key_base
    end

    def version_string
      return @version_string unless @version_string.nil?

      @version_string = version.number.to_s
      @version_string = "#{@version_string}-p#{git_revision[0..7]}" if git_available?
      @version_string
    end

    def git_available?
      return @git_available unless @git_available.nil?
      `which git`
      `git status 2> /dev/null` if $?.success?
      @git_available = $?.success?
    end

    def git_revision
      get_git_info if git_available?
      @git_revision
    end

    def git_update
      get_git_info if git_available?
      @git_update
    end

    def rails_asset_id
      (git_revision || version)[0..8]
    end

    def get_redis_options
      redis_url = ENV["REDIS_URL"] || environment.redis.get

      return {} unless redis_url.present?

      unless redis_url.start_with?("redis://", "unix:///")
        warn "WARNING: Your redis url (#{redis_url}) doesn't start with redis:// or unix:///"
      end
      { url: redis_url }
    end

    def sidekiq_log
      path = Pathname.new environment.sidekiq.log.get
      path = Rails.root.join(path) unless path.absolute?
      path.to_s
    end

    def postgres?
      ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
    end

    def bitcoin_donation_address
      AppConfig.settings.bitcoin_address if AppConfig.settings.bitcoin_address.present?
    end

    private

    def get_git_info
      return if git_info_present? || !git_available?

      git_cmd = `git log -1 --pretty="format:%H %ci"`
      if git_cmd =~ /^(\w+?)\s(.+)$/
        @git_revision = Regexp.last_match(1)
        @git_update = Regexp.last_match(2).strip
      end
    end

    def git_info_present?
      @git_revision || @git_update
    end
  end
end
