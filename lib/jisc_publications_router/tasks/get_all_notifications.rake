require "optparse"
require "jisc_publications_router"

namespace :jisc_publications_router do
  desc <<~notes
    get all notifications (since the last run). 
    You'll want to add an initializer in your rails application to 
    configure the JISC publications router client to your needs.
    
    Usage
      rake 'jisc_publications_router:get_all_notifications -- --save_response --save_notification --get_content'
      rake 'jisc_publications_router:get_all_notifications -- --sr --sn --gc'

    The arguments are optional. 
    Use --save_response or --sr if you want the responses saved in the notifications directory
    Use --save_notification or --sn if you want the notification metadata saved to the adapter
    Use --get_content or --gc if you want the notification content retreived and saved in the notifications directory
  notes

  task :get_all_notifications => :environment do

    options = {}
    option_parser = OptionParser.new
    option_parser.banner = 'Usage: rake jisc_publications_router:get_all_notifications [options]'

    option_parser.on('-sr', '--save_response', String, 'save response from JISC publications router api') do |save_response|
      options[:save_response] = true
    end

    option_parser.on('-sn', '--save_notification', String, 'save notification from JISC publications router api') do |save_notification|
      options[:save_notification] = true
    end

    option_parser.on('-gc', '--get_content', String, 'get content from JISC publications router api') do |get_content|
      options[:get_content] = true
    end

    args = option_parser.order!(ARGV) {}
    option_parser.parse!(args)

    save_response = false
    if options[:save_response].present?
      save_response = true
    end

    save_notification = false
    if options[:save_notification].present?
      save_notification = true
    end

    get_content = false
    if options[:get_content].present?
      get_content = true
    end

    raise JiscPublicationsRouter::Error, "Client Id is not configured" unless JiscPublicationsRouter.configuration.client_id
    raise JiscPublicationsRouter::Error, "API key is not configured" unless JiscPublicationsRouter.configuration.api_key
    raise JiscPublicationsRouter::Error, "Notifications dir is not configured" unless JiscPublicationsRouter.configuration.notifications_dir

    nl = JiscPublicationsRouter::V4::NotificationsList.new
    _all_notification_ids = nl.get_all_notifications(
      save_notification: save_notification,
      save_response: save_response,
      get_content: get_content)
  end

end
