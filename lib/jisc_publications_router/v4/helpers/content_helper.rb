require 'fileutils'

module JiscPublicationsRouter
  module V4
    module Helpers
      module ContentHelper
        include ::JiscPublicationsRouter::V4::Helpers::NotificationHelper
        private
        def _content_path(notification_id, content_link, original_filename)
          content_filename = _content_filename(content_link, original_filename)
          base_path = _notification_path(notification_id)
          base_name = File.basename(content_filename, ".*")
          extension = File.extname(content_filename)
          file_path = File.join(base_path, content_filename)
          suffix = 1
          while File.exist?(file_path)
            new_content_filename = "#{base_name}_#{suffix}#{extension}"
            file_path = File.join(base_path, new_content_filename)
            suffix += 1
          end
          file_path
        end

        def _content_filename(content_link, original_filename)
          return original_filename unless content_link
          "#{content_link.fetch('notification_type', '')}_#{original_filename}"
        end
      end
    end
  end
end
