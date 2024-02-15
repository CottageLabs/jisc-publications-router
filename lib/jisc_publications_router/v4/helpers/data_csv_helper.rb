require "csv"
require_relative './notification_helper'

module JiscPublicationsRouter
  module V4
    module Helpers
      module DataCsvHelper

        include NotificationHelper
        private

        def csv_headers
          %w[id identifier_doi identifier_issn identifier_eissn title type
            subject license_title license_url publication_status acceptance_date
            publication_date journal_title file_formats file_urls number_of_files]
        end

        def _do_csv_crosswalk(notification)
          csv_hash = {
            'id'=> get_id(notification),
            'identifier_doi' => get_doi(notification),
            'identifier_issn' => get_issn(notification),
            'identifier_eissn' => get_eissn(notification),
            'title' => get_title(notification),
            'type' => get_type(notification),
            'subject' => get_subject(notification),
            'license_title' => get_license_title(notification),
            'license_url' => get_license_url(notification),
            'publication_status' => get_publication_status(notification),
            'acceptance_date' => get_accepted_date(notification),
            'publication_date' => get_publication_date(notification),
            'journal_title' => get_journal_title(notification)
          }
          csv_hash = csv_hash.merge(get_file_info(notification))
          cleanup_and_flatten_hash(csv_hash)
        end
        def get_id(notification)
          notification.fetch('id', nil)
        end

        def get_doi(notification)
          ids = notification.dig('metadata', 'article', 'identifier')
          return nil unless ids
          dois = []
          ids.each do |id|
            dois.append(id['id']) if id.fetch('type', '') == 'doi' and id.fetch('id', nil).present?
          end
          dois
        end

        def get_issn(notification)
          ids = notification.dig('metadata', 'journal', 'identifier')
          return nil unless ids
          issns = []
          ids.each do |id|
            issns.append(id['id']) if id.fetch('type', '') == 'issn' and id.fetch('id', nil).present?
          end
          issns
        end

        def get_eissn(notification)
          ids = notification.dig('metadata', 'journal', 'identifier')
          return nil unless ids
          eissns = []
          ids.each do |id|
            eissns.append(id['id']) if id.fetch('type', '') == 'eissn' and id.fetch('id', nil).present?
          end
          eissns
        end

        def get_title(notification)
          notification.dig('metadata', 'article', 'title')
        end

        def get_type(notification)
          notification.dig('metadata', 'article', 'type')
        end

        def get_subject(notification)
          notification.dig('metadata', 'article', 'subject')
        end

        def get_license_title(notification)
          license_title = []
          ls = notification.dig('metadata', 'license_ref')
          return license_title unless ls
          ls.each do |lic|
            license_title << lic.fetch("title", nil)
          end
          license_title
        end

        def get_license_url(notification)
          license_url = []
          ls = notification.dig('metadata', 'license_ref')
          return license_url unless ls
          ls.each do |lic|
            license_url << lic.fetch("url", nil)
          end
          license_url
        end

        def get_publication_status(notification)
          notification.dig('metadata', 'publication_status')
        end

        def get_accepted_date(notification)
          notification.dig('metadata', 'accepted_date')
        end

        def get_publication_date(notification)
          notification.dig('metadata', 'publication_date', 'date')
        end

        def get_journal_title(notification)
          notification.dig('metadata', 'journal', 'title')
        end

        def get_version(notification)
          notification.dig('metadata', 'version')
        end

        def get_file_info(notification)
          content_links = _notification_content_links(notification)
          file_info= {
            'file_formats' => [],
            'file_urls' => [],
            'number_of_files' => content_links.size.to_s
          }
          content_links.each do |cl|
            file_info['file_formats'].append(cl['format'])
            file_info['file_urls'].append(cl['url'])
          end
          file_info
        end

        def cleanup_and_flatten_hash(csv_hash)
          new_hash = {}
          csv_hash.each do |k, v|
            new_val = Array(v).map{|val| val.to_s}.reject(&:empty?)
            new_hash[k] = new_val.join(";") if new_val.any?
          end
          new_hash
        end

        def _write_to_csv(response_body, csv_file)
          if File.exist?(csv_file)
            csv = CSV.open(csv_file, "ab", :headers => csv_headers,
                           :write_headers => false)
          else
            csv = CSV.open(csv_file, "wb", :headers => csv_headers,
                           :write_headers => true)
          end
          response_body.fetch("notifications", []).each do |notification|
            csv_hash = _do_csv_crosswalk(notification)
            csv << csv_hash
          end
          csv.close
        end

        def _get_csv_file_path
          file_path = File.join(JiscPublicationsRouter.configuration.notifications_dir,
                                "response_body")
          FileUtils.mkdir_p(file_path) unless File.directory?(file_path)
          current_time = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
          File.join(file_path, "notifications_#{current_time}.csv")
        end
      end
    end
  end
end
