require 'fileutils'

module JiscPublicationsRouter
  module V4
    module Helpers
      module ContentHelper
        include ::JiscPublicationsRouter::V4::Helpers::NotificationHelper
        private
        def _content_path(notification_id, content_link, original_filename)
          File.join(_notification_path(notification_id),
                    _content_filename(content_link, original_filename))
        end

        def _content_filename(content_link, original_filename)
          return original_filename unless content_link
          "#{content_link.fetch('notification_type', '')}_#{original_filename}"
        end

        def _error_filename(content_link)
          ".#{content_link.fetch('notification_type', '')}_error"
        end

        def _content_error_file(notification_id, content_link)
          FileUtils.touch(File.join(_notification_path(notification_id),
                    _error_filename(content_link)))
        end
      end
    end
  end
end
