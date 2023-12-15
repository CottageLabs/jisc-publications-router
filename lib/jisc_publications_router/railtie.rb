require 'jisc_publications_router'
require 'rails'

module JiscPublicationsRouter
  class Railtie < Rails::Railtie
    railtie_name :jisc_publications_router

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/*.rake").each { |f| load f }
    end
  end
end