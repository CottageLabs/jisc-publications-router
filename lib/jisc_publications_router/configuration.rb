# frozen_string_literal: true

module JiscPublicationsRouter
  class Configuration
    attr_accessor :client_id, :api_key, :notifications_dir, :api_endpoint,
                  :retry_count, :since_id_filename, :notifications_store_options,
                  :notifications_store_adapter, :packaging_formats,
                  :preferred_packaging_format, :retrieve_unpackaged

    def initialize(client_id = nil, api_key = nil, notifications_dir = nil,
                   api_endpoint = "https://pubrouter.jisc.ac.uk/api/v4",
                   retry_count = 3, since_id_filename = ".since",
                   notifications_store_adapter = "file",
                   preferred_packaging_format = "http://purl.org/net/sword/package/SimpleZip",
                   retrieve_unpackaged = false,
                   log_file = "jisc_publications_router.log")
      @notifications_store_options = %w[file sidekiq]
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
      @notifications_store_adapter = notifications_store_adapter
      @preferred_packaging_format = preferred_packaging_format
      @retrieve_unpackaged = retrieve_unpackaged
      validate_and_setup!
    end

    def validate_and_setup!
      validate_store_adapter(notifications_store_adapter)
      validate_preferred_packaging_format(preferred_packaging_format)
      create_notifications_directory
    end

    def validate_store_adapter(adapter)
      return if @notifications_store_options.include?(adapter)

      msg = "Invalid notifications_store_adapter. Choose from #{@notifications_store_options}"
      raise Error, msg
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
