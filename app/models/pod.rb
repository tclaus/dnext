# frozen_string_literal: true

class Pod < ApplicationRecord
  enum status: {unchecked: 0, no_errors: 1, dns_failed: 2, net_failed: 3, ssl_failed: 4,
http_failed: 5, version_failed: 6, unknown_error: 7}

  ERROR_MAP = {
    ConnectionTester::AddressFailure  => :dns_failed,
    ConnectionTester::DNSFailure      => :dns_failed,
    ConnectionTester::NetFailure      => :net_failed,
    ConnectionTester::SSLFailure      => :ssl_failed,
    ConnectionTester::HTTPFailure     => :http_failed,
    ConnectionTester::NodeInfoFailure => :version_failed
  }.freeze

  # this are only the most common errors, the rest will be +unknown_error+
  CURL_ERROR_MAP = {
    couldnt_resolve_host:         :dns_failed,
    couldnt_connect:              :net_failed,
    operation_timedout:           :net_failed,
    ssl_cipher:                   :ssl_failed,
    ssl_cacert:                   :ssl_failed,
    redirected_to_other_hostname: :http_failed
  }.freeze

  DEFAULT_PORTS = [URI::HTTP::DEFAULT_PORT, URI::HTTPS::DEFAULT_PORT].freeze

  has_many :people

  scope :check_failed, lambda {
    where(arel_table[:status].gt(Pod.statuses[:no_errors])).where.not(status: Pod.statuses[:version_failed])
  }

  validate :not_own_pod

  class << self
    def find_or_create_by(opts)
      # Rename this method to not override an AR method
      uri = URI.parse(opts.fetch(:url))
      port = DEFAULT_PORTS.include?(uri.port) ? nil : uri.port
      find_or_initialize_by(host: uri.host, port: port).tap do |pod|
        pod.ssl ||= (uri.scheme == "https")
        pod.save
      end
    end

    # don't consider a failed version reading to be fatal
    def offline_statuses
      [Pod.statuses[:dns_failed],
       Pod.statuses[:net_failed],
       Pod.statuses[:ssl_failed],
       Pod.statuses[:http_failed],
       Pod.statuses[:unknown_error]]
    end

    def check_all!
      Pod.find_in_batches(batch_size: 20) {|batch| batch.each(&:test_connection!) }
    end

    # Checks all seed pods without any check so far.
    def check_all_unchecked!
      Pod.where(checked_at: "1970-01-01 00:00:00")
         .find_in_batches(batch_size: 20) {|batch| batch.each(&:test_connection!) }
    end

    def check_scheduled!
      Pod.where(scheduled_check: true).find_each(&:test_connection!)
    end
  end

  def offline?
    Pod.offline_statuses.include?(Pod.statuses[status])
  end

  # a pod is active if it is online or was online less than 14 days ago
  def active?
    !offline? || offline_since.try {|date| date > DateTime.now.utc - 14.days }
  end

  def to_s
    "#{id}:#{host}"
  end

  def schedule_check_if_needed
    update_column(:scheduled_check, true) if offline? && !scheduled_check
  end

  def test_connection!
    result = ConnectionTester.check uri.to_s
    logger.debug "Tested pod: '#{uri}' - #{result.inspect}"

    transaction do
      update_from_result(result)
    end
  end

  # @param path [String]
  # @return [String]
  def url_to(path)
    uri.tap {|uri| uri.path = path }.to_s
  end

  def update_offline_since
    if offline?
      self.offline_since ||= DateTime.now.utc
    else
      self.offline_since = nil
    end
  end

  # @return [URI]
  def uri
    @uri ||= (ssl ? URI::HTTPS : URI::HTTP).build(host: host, port: port)
    @uri.dup
  end

  private

  def update_from_result(result)
    self.status = status_from_result(result)
    update_offline_since
    logger.warn "OFFLINE #{result.failure_message}" if offline?

    attributes_from_result(result)
    touch(:checked_at)
    self.scheduled_check = false

    save
  end

  def attributes_from_result(result)
    self.ssl ||= result.ssl
    self.port = 443 if result.ssl
    self.error = result.failure_message[0..254] if result.error?
    self.error = nil if result.error.nil?
    self.software = result.software_version[0..254] if result.software_version.present?
    self.response_time = result.rt
  end

  def status_from_result(result)
    if result.error?
      ERROR_MAP.fetch(result.error.class, :unknown_error)
    else
      :no_errors
    end
  end

  def not_own_pod
    pod_uri = AppConfig.pod_uri
    pod_port = DEFAULT_PORTS.include?(pod_uri.port) ? nil : pod_uri.port
    errors.add(:base, "own pod not allowed") if pod_uri.host == host && pod_port == port
  end
end
