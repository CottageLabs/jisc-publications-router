# frozen_string_literal: true

require "json"
require_relative "./helpers"

module JiscPublicationsRouter
  module V4
    class NotificationsList
      include ::JiscPublicationsRouter::V4::Helpers

      def initialize
        @tries = {}
      end

      def get_all_notifications(since: nil, since_id: nil, page_number: 1, page_size: nil,
                                max_number_of_pages: 10000, save_response: false)
        JiscPublicationsRouter.logger.info("Starting to get all notifications")
        csv_file = _get_csv_file_path
        since, since_id = _gather_since_or_since_id if (since.nil? || since.empty?) && (since_id.nil? || since_id.empty?)
        all_notification_ids = []
        number_of_pages = 1
        while page_number <= [number_of_pages, max_number_of_pages].min
          # Use only since or since_id.
          # Sending page_number along with since or since_id confuses the response when iterative
          # Not adding this to a list, as we want this to be sequential. Much easier to keep track
          # of the last notification that has been obtained.
          begin
            # initialising number of tries
            since ? @tries[since] ||= 0 : @tries[since_id.to_s] ||= 0
            # incrementing tries
            since ? @tries[since] += 1 : @tries[since_id.to_s] += 1
            response_body,
              notification_ids,
              new_since_id = get_notifications_list(since: since, since_id: since_id,
                                                    page_number: nil, page_size: page_size,
                                                    save_response: save_response, csv_file: csv_file)

            all_notification_ids.concat(notification_ids)
          rescue StandardError => e
            tries = since ? @tries[since] ||= 0 : @tries[since_id.to_s] ||= 0
            from = ""
            from = since if since
            from = since_id if since_id
            msg1 = "List notifications error, since #{from}, try #{tries} : #{e.class}, message: #{e.message}"
            msg2 = "List notifications error, since #{from}, try #{tries} : backtrace: #{e.backtrace.join("\n")}"
            JiscPublicationsRouter.logger.warn(msg1)
            JiscPublicationsRouter.logger.warn(msg2)
            # If a request fails, retry {retry_count} times before aborting
            if tries > JiscPublicationsRouter.configuration.retry_count
              JiscPublicationsRouter.logger.error("Lost notifications error, since #{from}, try #{tries} : All tries exhausted. Aborting")
              return
            end

            new_since_id = nil
          end
          next unless new_since_id
          number_of_pages = _total_number_of_pages(response_body) if page_number == 1
          since = nil
          since_id = new_since_id
          page_number += 1
        end
        all_notification_ids
      end

      def get_notifications_list(since: nil, since_id: nil, page_number: 1, page_size: nil,
                                 save_response: false, csv_file: _get_csv_file_path)
        _validate_list_params(since, since_id)
        if since
          msg = "Getting list of notifications since #{since}"
        else
          msg = "Getting list of notifications since id #{since_id}"
        end
        JiscPublicationsRouter.logger.info(msg)
        params = if since.present?
                   { api_key: JiscPublicationsRouter.configuration.api_key, since: since }
                 else
                   { api_key: JiscPublicationsRouter.configuration.api_key, since_id: since_id }
                 end
        params[:page] = page_number if page_number.present?
        params[:pageSize] = page_size if page_size.present?
        # From reading SO posts, using file.join to join URI parts as opposed
        # to any of the URI methods, as this works best
        uri = URI(File.join(JiscPublicationsRouter.configuration.api_endpoint, "routed",
                            JiscPublicationsRouter.configuration.client_id))
        JiscPublicationsRouter.logger.info("Getting list of notifications #{uri.to_s}")
        uri.query = URI.encode_www_form(params)
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        _response, response_body = _do_request(request)
        notification_ids = _notification_ids(response_body)
        since_id = notification_ids[-1]
        if save_response
          _save_response(response_body)
          _write_to_csv(response_body, csv_file)
        end
        response_body['notifications'].each do |notification|
          _use_notification_data(notification)
        end
        _save_since_id(since_id) if since_id
        JiscPublicationsRouter.logger.info("Completed getting list of notifications")
        [response_body, notification_ids, since_id]
      end
    end
  end
end
