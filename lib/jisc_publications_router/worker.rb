# frozen_string_literal: true

require "sidekiq"
require "down"
require_relative "./v4/helpers/notification_helper"

module JiscPublicationsRouter
  module Worker
    class NotificationWorker
      WORKER_LOGGER = Logger.new('log/notification_worker.log')

      include Sidekiq::Worker
      sidekiq_options queue: :notification, retry: false, backtrace: true

      def perform(notification_id, notification_path); end

      def self.add_to_notification_worker(notification_id, notification_path)
        Sidekiq::Client.enqueue_to "notification", NotificationWorker,
                                   "notification_id" => notification_id,
                                   "notification_path" => notification_path
        WORKER_LOGGER.debug("Notification #{notification['id']} added to queue")
      end
    end

    class NotificationContentWorker
      include Sidekiq::Worker
      include JiscPublicationsRouter::V4::Helpers::NotificationHelper
      # TODO: set number of retries
      sidekiq_options queue: :notification_content, retry: true, backtrace: true

      WORKER_LOGGER = Logger.new('log/notification_content_worker.log')
      WORKER_LOGGER.level = Logger::INFO

      sidekiq_retries_exhausted do |msg, exception|
        notification_id = msg['args'][0]
        _content_link = msg['args'][1]
        title = "Notification #{notification_id}: Failed to fetch content"
        # create a log entry
        WORKER_LOGGER.error("#{title} #{msg['class']}: #{msg['error_message']}", error: exception)
      end

      def perform(notification_id, content_links)
        downloaded_content_links = []
        content_links.each do |content_link|
          WORKER_LOGGER.debug("Notification #{notification_id}: Retrieving #{content_link['url']}")
          begin
            nc = JiscPublicationsRouter::V4::NotificationContent.new()
            content_path = nc.get_content(notification_id, content_link)
            content_link['file_path'] = content_path
            downloaded_content_links.append(content_link)
          rescue Down::InvalidUrl, Down::TooManyRedirects, Down::NotFound
            # create a log entry
            WORKER_LOGGER.warn("Notification #{notification_id}: Failed to fetch content #{content_link['url']}")
            raise
          ensure
            _write_content_links_to_file(notification_id, downloaded_content_links) if downloaded_content_links.size > 0
          end
        end
        _queue_notification(notification_id)
      end
    end
  end
end

