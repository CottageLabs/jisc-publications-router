require "optparse"
require "jisc_publications_router"

namespace :jisc_publications_router do
  desc 'get all notifications (since the last run)'
  task :get_all_notifications => :environment do

    options = {}
    option_parser = OptionParser.new
    option_parser.banner = 'Usage: rake jisc_publications_router:get_all_notifications [options]'

    option_parser.on('-cOPTIONAL', '--client_id=CLIENT_ID', String, 'The client_id for the JISC publications router API') do |client_id|
      options[:client_id] = client_id
    end

    option_parser.on('-kOPTIONAL', '--api_key=API_KEY', String, 'The api_key to to authorise connections to the JISC publications router') do |api_key|
      options[:api_key] = api_key
    end

    option_parser.on('-dOPTIONAL', '--notifications_dir=NOTIFICATIONS_DIR', String, 'The directory used by the gem to store data from the API calls ') do |notifications_dir|
      options[:notifications_dir] = notifications_dir
    end

    option_parser.on('-s', '--save_response', String, 'save response from JISC publications router api') do |save_response|
      options[:save_response] = true
    end

    args = option_parser.order!(ARGV) {}
    option_parser.parse!(args)

    if options[:client_id].present? and options[:api_key].present? and options[:notifications_dir].present?
      JiscPublicationsRouter.configure do |config|
        config.client_id = options[:client_id]
        config.api_key = options[:api_key]
        config.notifications_dir = options[:notifications_dir]
      end
    end
    raise JiscPublicationsRouter::Error, "Client Id is not configured" unless JiscPublicationsRouter.configuration.client_id
    raise JiscPublicationsRouter::Error, "API key is not configured" unless JiscPublicationsRouter.configuration.api_key
    raise JiscPublicationsRouter::Error, "Notifications dir is not configured" unless JiscPublicationsRouter.configuration.notifications_dir

    save_response = false
    if options[:save_response].present?
      save_response = true
    end
    nl = JiscPublicationsRouter::V4::NotificationsList.new
    _all_notification_ids = nl.get_all_notifications(save_response: save_response)
  end

end
