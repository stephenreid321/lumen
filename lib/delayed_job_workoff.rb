if ENV['HEROKU_WORKOFF'] and ENV['HEROKU_OAUTH_TOKEN']
  module Delayed
    module Plugins
      class Workoff < Plugin
        callbacks do |lifecycle|
          lifecycle.after(:enqueue) do |job|          
            heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
            heroku.dyno.create(ENV['APP_NAME'], {command: "rake jobs:workoff"})
          end
        end
      end
    end
  end

  Delayed::Worker.plugins << Delayed::Plugins::MyDelayedJobPlugin
end