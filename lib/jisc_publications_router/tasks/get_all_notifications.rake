require "optparse"
require "jisc_publications_router"

namespace :jisc_publications_router do
  desc <<~notes
    get all notifications (since the last run). 
    You will need to add an initializer in your rails application to 
    configure the JISC publications router client before running the rake task.
    
    Usage
      rake 'jisc_publications_router:get_all_notifications'
      rake 'jisc_publications_router:get_all_notifications -- --save_response'
      rake 'jisc_publications_router:get_all_notifications -- --sr'

    The argument is optional. 
    Use --save_response / --sr if you want the responses saved in the notifications directory.
  notes

  task :get_all_notifications => :environment do

    options = {}
    option_parser = OptionParser.new
    option_parser.banner = 'Usage: rake jisc_publications_router:get_all_notifications [options]'

    option_parser.on('-sr', '--save_response', String, 'save response from JISC publications router api') do |save_response|
      options[:save_response] = true
    end

    args = option_parser.order!(ARGV) {}
    option_parser.parse!(args)

    save_response = false
    if options[:save_response].present?
      save_response = true
    end

    raise JiscPublicationsRouter::Error, "Client Id is not configured" unless JiscPublicationsRouter.configuration.client_id
    raise JiscPublicationsRouter::Error, "API key is not configured" unless JiscPublicationsRouter.configuration.api_key
    raise JiscPublicationsRouter::Error, "Notifications dir is not configured" unless JiscPublicationsRouter.configuration.notifications_dir

    nl = JiscPublicationsRouter::V4::NotificationsList.new
    _all_notification_ids = nl.get_all_notifications(save_response: save_response)
  end

end
