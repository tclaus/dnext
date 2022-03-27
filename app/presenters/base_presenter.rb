# frozen_string_literal: true

class BasePresenter
  attr_reader :current_user

  include Rails.application.routes.url_helpers

  class << self
    def new(*args)
      return NilPresenter.new if args[0].nil?

      super(*args)
    end
  end

  def initialize(presentable, curr_user=nil)
    @presentable = presentable
    @current_user = curr_user
  end

  def respond_to_missing?(name, include_private)
    @presentable.respond_to?(name) || super
  end

  def method_missing(method, *args)
    @presentable.public_send(method, *args)
  end

  private

  def default_url_options
    {host: AppConfig.pod_uri.host, port: AppConfig.pod_uri.port}
  end
end
