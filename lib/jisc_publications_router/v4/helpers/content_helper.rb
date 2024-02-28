require 'fileutils'
require 'zip'
require 'mimemagic'
require 'digest'

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

        def _extract_select_files_from_zip(notification_id, content_link, content_path)
          selected_files = []
          if File.exist?(content_path)
            _extract_zip_file(content_path)
            selected_files = _select_files_from_zip(notification_id, content_link, content_path)
          end
          selected_files
        end

        def _extract_zip_file(content_path)
          # Creating a directory in the same name as zip file
          FileUtils.mkdir_p(content_path)
          Zip::File.open(content_path) do |zip_file|
            zip_file.each do |zip_entry|
              fpath = File.join(content_path, zip_entry.name)
              zip_file.extract(zip_entry, fpath) unless File.exist?(fpath)
            end
          end
        end

        def _select_files_from_zip(notification_id, content_link, content_dir)
          # only interested in extensions in _file_suffix_to_mime_type_mappings (excluding zip)
          # Not dealing with recursive zips
          # The selected file will be moved to the notification dir, so it's flat
          selected_files = []
          return selected_files unless File.directory?(content_dir)
          Dir.glob("#{content_dir}/**/*").each do |f|
            next unless File.file?(f)
            ext = _get_mime_type(f)
            if ext and not ['other', 'zip'].include?(ext)
              filename_ext = File.extname(f)
              filename = File.basename(f, filename_ext)
              original_filename = "#{filename}.#{ext}"
              new_file_path = _content_path(notification_id, content_link, original_filename)
              FileUtils.mv(f, new_file_path)
              selected_files << _get_file_hash(new_file_path)
            end
          end
          selected_files
        end

        def _get_file_hash(content_path)
          ext = _get_mime_type(content_path)
          mime_type = nil
          mime_type = _file_suffix_to_mime_type_mappings[ext] if _file_suffix_to_mime_type_mappings.include?(ext)
          file_hash = {
            'file_path' => content_path,
            'file_name' => File.basename(content_path),
            'file_size' => _get_file_size(content_path),
            'file_mime_type' => mime_type,
            'file_sha1' => _get_file_sha1(content_path)
          }
          return file_hash
        end

        def _get_file_sha1(content_path)
          file_sha1 = nil
          file_sha1 = Digest::SHA1.file(file_path).hexdigest if File.exist?(content_path)
          file_sha1
        end

        def _get_file_size(content_path)
          file_size = nil
          file_size = "#{File.size(content_path)}" if File.exist?(content_path)
          file_size
        end

        def _get_mime_type(file_path)
          begin
            mime_type = MimeMagic.by_magic(open(file_path))&.type
            ext = _file_suffix_to_mime_type_mappings.key(mime_type)
            if ext
              return ext
            elsif mime_type == 'x-ole-storage'
              # check for .doc, .xls, .ppt
              IO.popen(["file", "--mime-type", "--brief", "#{file_path}"]) do |io|
                ext = _file_suffix_to_mime_type_mappings.key(io.read.chomp)
                return ext if ext
              end
            end
            return 'other'
          rescue => ex
            return nil
          end
        end

        def _file_suffix_to_mime_type_mappings
          { 'csv'  => 'text/csv',
            'doc'  => 'application/msword',
            'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'odp'  => 'application/vnd.oasis.opendocument.presentation',
            'ods'  => 'application/vnd.oasis.opendocument.spreadsheet',
            'odt'  => 'application/vnd.oasis.opendocument.text',
            'pdf'  => 'application/pdf',
            'ppt'  => 'application/vnd.ms-powerpoint',
            'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'rtf'  => 'application/rtf',
            'tex'  => 'application/x-tex',
            'xls'  => 'application/vnd.ms-excel',
            'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'zip'  => 'application/zip' }
        end

      end
    end
  end
end
