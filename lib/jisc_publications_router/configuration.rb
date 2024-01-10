# frozen_string_literal: true

require "sidekiq"

module JiscPublicationsRouter
  class Configuration
    attr_accessor :client_id, :api_key, :notifications_dir, :api_endpoint,
                  :retry_count, :since_id_filename, :preferred_packaging_format,
                  :packaging_formats, :retrieve_unpackaged, retrieve_content, :log_file

    def initialize(client_id = nil, api_key = nil, notifications_dir = nil,
                   api_endpoint = "https://pubrouter.jisc.ac.uk/api/v4",
                   retry_count = 3, since_id_filename = ".since",
                   preferred_packaging_format = "http://purl.org/net/sword/package/SimpleZip",
                   retrieve_unpackaged = false,
                   retrieve_content =true,
                   log_file = "log/jisc_publications_router.log",
                   redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
                   redis_password= ENV.fetch("REDIS_PASSWORD", ""))
      @packaging_formats = [
        "https://pubrouter.jisc.ac.uk/FilesAndJATS",
        "http://purl.org/net/sword/package/SimpleZip"
      ]
      @client_id = client_id
      @api_key = api_key
      @notifications_dir = notifications_dir
      @api_endpoint = api_endpoint
      @retry_count = retry_count
      @since_id_filename = since_id_filename
      @preferred_packaging_format = preferred_packaging_format
      @retrieve_unpackaged = retrieve_unpackaged
      @retrieve_content = retrieve_content
      @log_file = log_file
      validate_and_setup!
      redis_config = { url: redis_url }
      redis_config[:password] = redis_password if redis_password
      Sidekiq.configure_server do |config|
        config.redis = redis_config
      end
      Sidekiq.configure_client do |config|
        config.redis = redis_config
      end
    end

    def validate_and_setup!
      validate_preferred_packaging_format(@preferred_packaging_format)
      create_notifications_directory
      JiscPublicationsRouter.logger = Logger.new(@log_file) if @log_file and @log_file != "log/jisc_publications_router.log"
    end

    def validate_preferred_packaging_format(pf)
      return if @packaging_formats.include?(pf)

      msg = "Invalid preferred_packaging_format option. Choose from #{@packaging_formats}"
      raise Error, msg
    end

    def create_notifications_directory
      return unless @notifications_dir

      begin
        FileUtils.mkdir_p(@notifications_dir) unless File.directory?(@notifications_dir)
      rescue StandardError
        msg = "notifications_dir is not a valid directory."
        raise Error, msg
      end
    end
  end
end
