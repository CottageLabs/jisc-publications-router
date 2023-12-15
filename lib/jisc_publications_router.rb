# frozen_string_literal: true

require "jisc_publications_router/version"
require "jisc_publications_router/configuration"
require "jisc_publications_router/v4/notifications_list"
require "jisc_publications_router/v4/notification"
require "jisc_publications_router/worker"
require "jisc_publications_router/v4/helpers"

module JiscPublicationsRouter
  require 'jisc_publications_router/railtie' if defined?(Rails)
  class Error < StandardError; end

  class APIError < StandardError
    def initialize(code, message)
      if message && message != ""
        super("#{code}: #{message}")
      else
        super(code.to_s)
      end
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @@configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
    configuration.validate_and_setup!
  end

  def self.logger
    @@logger = Logger.new("log/jisc_publications_router.log")
  end

  def self.logger=(logger)
    @@logger = logger
  end
end
