# frozen_string_literal: true

require "sidekiq"
require_relative "./v4/helpers"

module JiscPublicationsRouter
  module Worker
    class NotificationWorker
      WORKER_LOGGER = Logger.new('log/notification_worker.log')

      include Sidekiq::Worker
      sidekiq_options queue: :notification, retry: false, backtrace: true

      def perform(json_notification, json_content_links); end

      def self.add_to_notification_worker(notification)
        Sidekiq::Client.enqueue_to "notification", NotificationWorker,
                                   "notification" => notification.to_json
        WORKER_LOGGER.debug("Notification #{notification['id']} added to queue")
      end
    end

    class NotificationContentWorker
      include Sidekiq::Worker
      # TODO: set number of retries
      sidekiq_options queue: :notification_content, retry: true, backtrace: true

      WORKER_LOGGER = Logger.new('log/notification_content_worker.log')
      WORKER_LOGGER.level = Logger::INFO

      sidekiq_retries_exhausted do |msg, exception|
        notification_id = msg['args'][0]
        content_link = msg['args'][1]
        title = "Notification #{notification_id}: Failed to fetch content #{content_link['url']}"
        # create error in notifications dir if it has finished all retries.
        _content_error_file(notification_id, content_link)
        # create a log entry
        WORKER_LOGGER.error("#{title} #{msg['class']}: #{msg['error_message']}", error: exception)
      end

      def perform(notification_id, content_link)
        nc = JiscPublicationsRouter::V4::NotificationContent.new()
        nc.get_content(notification_id, content_link)
      rescue Down::InvalidUrl, Down::TooManyRedirects, Down::NotFound
        # create error in notifications dir if it has finished all retries.
        _content_error_file(notification_id, content_link)
        # create a log entry
        WORKER_LOGGER.error("Notification #{notification_id}: Failed to fetch content #{content_link['url']}")
      end
    end
  end
end

