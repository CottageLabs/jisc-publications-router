# frozen_string_literal: true

require_relative './helpers/notification_list_helper'
require_relative './helpers/notification_helper'
require_relative './helpers/content_helper'

module JiscPublicationsRouter
  module V4
    module Helpers
      include NotificationListHelper
      include NotificationHelper
      include ContentHelper

      private

      def _do_request(request)
        base_uri = URI(JiscPublicationsRouter.configuration.api_endpoint)
        request_options = { use_ssl: base_uri.scheme == "https" }
        response = Net::HTTP.start(base_uri.hostname, base_uri.port, request_options) do |http|
          http.request(request)
        end
        begin
          response_body = JSON.parse(response.body)
        rescue StandardError
          response_body = response.body
        end
        unless response.response.code.to_i.between?(200, 299)
          raise JiscPublicationsRouter::APIError.new(response.response.code,
                                                     response_body["error"])
        end
        [response, response_body]
      end

      def _save_response(response_body)
        JiscPublicationsRouter.logger.debug("Saving response body")
        # response directory
        file_path = File.join(JiscPublicationsRouter.configuration.notifications_dir,
                              "response_body")
        FileUtils.mkdir_p(file_path) unless File.directory?(file_path)
        # response_body saved to file
        current_time = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
        _save_json(File.join(file_path, "#{current_time}.json"), response_body)
      end

      def _save_json(file_path, response_body)
        File.open(file_path, "w") do |f|
          f << JSON.pretty_generate(response_body)
        end
      end
    end
  end
end
