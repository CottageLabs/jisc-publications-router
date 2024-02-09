# frozen_string_literal: true
#
require "down"
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
        JiscPublicationsRouter.logger.info("Getting notification content #{notification_id}, #{content_link['url']}")
        params = {
          api_key: JiscPublicationsRouter.configuration.api_key
        }
        # From reading SO posts, using file.join to join URI parts as opposed
        # to any of the URI methods, as this works best
        uri = URI(content_link['url'])
        uri.query = URI.encode_www_form(params)
        tempfile = Down::NetHttp.download(uri, max_redirects: 10)
        # This will raise the following exceptions if the download fails
        # Down::InvalidUrl, Down::TooManyRedirects, Down::NotFound
          # raise exception and fail the job. Do not retry
        # Down::ServerError, Down::ConnectionError, Down::TimeoutError, Down::TimeoutError
          # raise exception and fail the job. It should retry
        content_path = _content_path(notification_id, content_link, tempfile.original_filename)
        FileUtils.mv(tempfile.path, content_path)
        content_path
      end
    end
  end
end
