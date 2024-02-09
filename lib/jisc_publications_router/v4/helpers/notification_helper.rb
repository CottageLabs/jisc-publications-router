module JiscPublicationsRouter
  module V4
    module Helpers
      module NotificationHelper
        private

        def _notification_path(notification_id)
          File.join(JiscPublicationsRouter.configuration.notifications_dir,
                    notification_id.to_s[0, 2],
                    notification_id.to_s[2, 2],
                    notification_id.to_s)
        end

        def _use_notification_data(notification)
          retrieve_content = JiscPublicationsRouter.configuration.retrieve_content
          # Save the notification
          _save_notification(notification)
          _save_content_links(notification)
          if retrieve_content
            _queue_content_links(notification)
          else
            _queue_notification(notification['id'])
          end
        end

        def _save_notification(notification)
          JiscPublicationsRouter.logger.debug("Notification #{notification['id']}: Saving notification ")
          notification_id = notification["id"]
          # create directory
          notification_path = _notification_path(notification_id)
          FileUtils.mkdir_p(notification_path) unless File.directory? notification_path
          # save notification
          metadata_file = File.join(notification_path, "notification.json")
          _save_json(metadata_file, notification)
        end

        def _save_content_links(notification)
          content_links = _notification_content_links(notification)
          return if content_links.size == 0
          _write_content_links_to_file(notification['id'], content_links)
        end

        def _write_content_links_to_file(notification_id, content_links)
          JiscPublicationsRouter.logger.debug("Notification #{notification_id}: saving content link")
          notification_path = _notification_path(notification_id)
          # create directory
          FileUtils.mkdir_p(notification_path) unless File.directory? notification_path
          # save content_links
          content_link_file = File.join(notification_path, "content_links.json")
          _save_json(content_link_file, content_links)
        end

        def _notification_content_links(notification)
          # packaging format - simple zip
          #       {
          #         "type" : "package",
          #         "access": "router",
          #         "format" : "application/zip",
          #         "url" : "https://pubrouter.jisc.ac.uk/api/v4/notification/123456789/content/SimpleZip.zip",
          #         "packaging" : "http://purl.org/net/sword/package/SimpleZip"
          #     }
          # packaging format - JATS
          #       {
          #         "type" : "package",
          #         "access": "router",
          #         "format" : "application/zip",
          #         "url" : "https://pubrouter.jisc.ac.uk/api/v4/notification/123456789/content",
          #         "packaging" : "https://pubrouter.jisc.ac.uk/FilesAndJATS"
          #     }
          # fulltext
          #     {
          #         "type": "fulltext",
          #         "access": "public",
          #         "format": "application/pdf",
          #         "url": "https://some_publisher_site.com/some_file_name.pdf"
          #     }
          # special pdf
          #     {
          #         "url": "https://pubrouter.jisc.ac.uk/api/v4/notification/123456789/content/eprints-rioxx/article.pdf",
          #         "format": "application/pdf",
          #         "type": "unpackaged",
          #         "access": "special"
          #     }
          # special non-pdf files
          #     {
          #         "url": "https://pubrouter.jisc.ac.uk/api/v4/notification/123456789/content/eprints-rioxx/non-pdf-files.zip",
          #         "format": "application/zip",
          #         "type": "unpackaged",
          #         "access": "special"
          #     }
          content_links = []
          notification.fetch('links', []).each do |link|
            next unless _content_needed?(link)
            content_link = link.clone
            content_link['need_api_key'] = _need_api_key(link)
            content_link['notification_type'] = _notification_type(link)
            msg = "#{notification['id']}: Notification type is #{content_link['notification_type']}"
            if content_link['need_api_key']
              msg += ", need api key"
            else
              msg += ", do not need api key"
            end
            JiscPublicationsRouter.logger.debug(msg)
            content_links.append(content_link)
          end
          content_links
        end

        def _need_api_key(content)
          case content.fetch('access', '')
          when 'public'
            need_api_key = false
          else
            need_api_key = true
          end
          need_api_key
        end

        def _content_needed?(content)
          # Need preferred packaging format, fulltext and unpackaged content if chosen
          preferred_packaging_format = JiscPublicationsRouter.configuration.preferred_packaging_format
          retrieve_unpackaged = JiscPublicationsRouter.configuration.retrieve_unpackaged
          need_content = false
          need_content = true if content.fetch('packaging', nil) == preferred_packaging_format
          need_content = true if content.fetch('type', nil) == 'fulltext'
          need_content = true if retrieve_unpackaged && content.fetch('type', nil) == 'unpackaged'
          need_content
        end

        def _notification_type(content)
          # 'FilesAndJATS' if
          #   type is package
          #   packaging is "https://pubrouter.jisc.ac.uk/FilesAndJATS"
          # 'SimpleZip' if
          #   type is package
          #   packaging is "http://purl.org/net/sword/package/SimpleZip"
          # 'Fulltext' if
          #   type is fulltext
          # 'UnpackagedPDF' if
          #   type is unpackaged
          #   format is "application/pdf"
          # 'UnpackagedZip' if
          #   type is unpackaged
          #   format is "application/zip"
          case content.fetch('type', 'none')
          when 'package'
            case content.fetch('packaging', 'other')
            when "https://pubrouter.jisc.ac.uk/FilesAndJATS"
              notification_type = 'FilesAndJATS'
            when "http://purl.org/net/sword/package/SimpleZip"
              notification_type = 'SimpleZip'
            else
              notification_type = 'PackagedOther'
            end
          when 'fulltext'
            notification_type = 'Fulltext'
          when 'unpackaged'
            case content.fetch('format', 'other')
            when "application/pdf"
              notification_type = "UnpackagedPDF"
            when "application/zip"
              notification_type = "UnpackagedZip"
            else
              notification_type = "UnpackagedOther"
            end
          else
            notification_type = 'Other'
          end
          notification_type
        end

        def _queue_content_links(notification)
          content_links = _notification_content_links(notification)
          JiscPublicationsRouter::Worker::NotificationContentWorker.
            perform_async(notification['id'], content_links)
        end

        def _queue_notification(notification_id)
          notification_path = _notification_path(notification_id)
          JiscPublicationsRouter.logger.debug("Notification #{notification_id}: Adding notification to queue")
          # JiscPublicationsRouter::Worker::NotificationWorker.
          # add_to_notification_worker(notification_id, notification_path)
          JiscPublicationsRouter::Worker::NotificationWorker.
            perform_async(notification_id, notification_path)
        end

        def _delete_notification_directory(notification_id)
          notification_path = _notification_path(notification_id)
          return unless Dir.exists?(notification_path)
          FileUtils.rm_r(notification_path)
          parent = File.dirname(notification_path)
          grand_parent = File.dirname(parent)
          _delete_empty_directory(parent)
          _delete_empty_directory(grand_parent)
        end

        def _delete_empty_directory(dir_name)
          if Dir.exists?(dir_name) && (Dir.entries(dir_name) - %w[ . .. ]).empty?
            FileUtils.rmdir(dir_name)
          end
        end

      end
    end
  end
end
