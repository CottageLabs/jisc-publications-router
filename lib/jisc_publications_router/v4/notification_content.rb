# frozen_string_literal: true
#
require "down"
require 'cgi'
require 'uri'
require "json"
require "fileutils"
require_relative "./helpers"

module JiscPublicationsRouter
  module V4
    class NotificationContent
      include ::JiscPublicationsRouter::V4::Helpers

      def initialize
        @tries = {}
      end

      def get_content(notification_id, content_link)
        JiscPublicationsRouter.logger.info("#{notification_id}: Getting notification content #{content_link['url']}")
        # From reading SO posts, using file.join to join URI parts as opposed
        # to any of the URI methods, as this works best
        uri = URI(content_link['url'])
        if content_link.fetch('need_api_key', false)
          params = uri.query ? CGI.parse(uri.query) : {}
          params[:api_key] = JiscPublicationsRouter.configuration.api_key
          uri.query = URI.encode_www_form(params)
        end
        tempfile = Down::NetHttp.download(uri, max_redirects: 10)
        # This will raise the following exceptions if the download fails
        # Down::InvalidUrl, Down::TooManyRedirects, Down::NotFound
          # raise exception and fail the job. Do not retry
        # Down::ServerError, Down::ConnectionError, Down::TimeoutError, Down::TimeoutError
          # raise exception and fail the job. It should retry
        content_path = _content_path(notification_id, content_link, tempfile.original_filename)
        FileUtils.mv(tempfile.path, content_path)
        JiscPublicationsRouter.logger.info("#{notification_id}: #{content_link['url']} saved to #{content_path}")
        _get_file_hash(content_path)
      end

      def extract_select_files_from_zip(notification_id, content_link, content_path)
        _extract_select_files_from_zip(notification_id, content_link, content_path)
      end
    end
  end
end
