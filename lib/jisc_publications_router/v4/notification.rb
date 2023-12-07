# frozen_string_literal: true

require "json"
require_relative "./helpers"

module JiscPublicationsRouter
  module V4
    class Notification
      include ::JiscPublicationsRouter::V4::Helpers

      def initialize
        @adapter = JiscPublicationsRouter.configuration.notifications_store_adapter
        @tries = {}
      end

      def get_notification(notification_id, save_notification: true, get_content: true)
        JiscPublicationsRouter.logger.info("Getting notification #{notification_id}")
        params = { api_key: JiscPublicationsRouter.configuration.api_key }
        # From reading SO posts, using file.join to join URI parts as opposed
        # to any of the URI methods, as this works best
        uri = URI(File.join(JiscPublicationsRouter.configuration.api_endpoint, "notification",
                            notification_id))
        uri.query = URI.encode_www_form(params)
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        _response, response_body = _do_request(request)
        # save notification
        _save_or_queue_all_notification_data(response_body) if save_notification
        _queue_content_links(response_body) if get_content
        response_body
      end
    end
  end
end
