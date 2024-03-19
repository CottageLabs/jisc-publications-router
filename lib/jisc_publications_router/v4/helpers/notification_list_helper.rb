module JiscPublicationsRouter
  module V4
    module Helpers
      module NotificationListHelper
        private

        def _since_id_filepath
          if JiscPublicationsRouter.configuration.since_id_filepath.present? and
             JiscPublicationsRouter.configuration.since_id_filepath != ".since"
            path = JiscPublicationsRouter.configuration.since_id_filepath
          else
            path = File.join(JiscPublicationsRouter.configuration.notifications_dir, ".since")
          end
          path
        end

        def _gather_since_or_since_id
          since_id = nil
          since = nil
          if File.exist?(_since_id_filepath)
            since_id = JSON.parse(File.read(_since_id_filepath))
          else
            since = "1970-01-01"
          end
          JiscPublicationsRouter.logger.debug("Gathered since #{since}") if since
          JiscPublicationsRouter.logger.debug("Gathered since_id #{since_id}") if since_id
          [since, since_id]
        end

        def _validate_list_params(since, since_id)
          error_message = nil
          error_message = "Need parameter since or since_id" if (since.nil? || since.empty?) && (since_id.nil? || since_id.empty?)

          if since && !_valid_since?(since)
            valid_format = "YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ"
            error_message = "Format of date #{since} is not valid. It has to be #{valid_format}"
          end
          return unless error_message

          raise JiscPublicationsRouter::Error, error_message
        end

        def _valid_since?(since)
          # since has to be of the format YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ
          since_date = if since.include?("T")
                         begin
                           Date.strptime(since, "%Y-%m-%dT%H:%M:%SZ")
                         rescue StandardError
                           nil
                         end
                       else
                         begin
                           Date.strptime(since, "%Y-%m-%d")
                         rescue StandardError
                           nil
                         end
                       end
          since_date.present?
        end

        def _total_number_of_pages(response_body)
          JiscPublicationsRouter.logger.debug("Gathering total number of pages from response")
          total = response_body.fetch("total", 0)
          page_size = response_body.fetch("pageSize", response_body.fetch("notifications", []).size)
          number_of_pages = 1
          if total > page_size
            number_of_pages, remainder = total.divmod(page_size)
            number_of_pages += 1 if remainder.positive?
          end
          number_of_pages
        end

        def _notification_ids(response_body)
          JiscPublicationsRouter.logger.debug("Gathering notification ids from response")
          response_body.fetch("notifications", []).map { |x| x["id"].to_s }
        end

        def _save_since_id(since_id)
          JiscPublicationsRouter.logger.debug("Saving since id #{since_id}")
          File.open(_since_id_filepath, "w") do |f|
            f << JSON.dump(since_id)
          end
        end

      end
    end
  end
end
