# frozen_string_literal: true

require_relative 'lib/manager'

# The base API URL for Lokic.
API_URL = 'https://lokic.locallabs.com/api/v1/scrape_tasks/'

# The base URL for Lokic.
LOKIC_URL = 'https://lokic.locallabs.com/scrape_tasks/'

# The only statuses to be checked
CHECKED_STATUSES = ["on checking", "done"]

# The Slack user ID for Oleksii Kuts.
OLEKSII_KUTS = 'U03F2H0PB2T'

# The Slack user ID for Art Jarocki.
ART_JAROCKI_SLACK_ID = 'ULCFVUK44'

# The Slack channel ID for HLE hamster messages.
HLE_HAMSTER_MESSAGES = 'G01GAM63FD0'

# The Slack channel ID for HLE scrape developers.
HLE_SCRAPE_DEVS = 'G01CY84KMT6'

# The default Slack channel to post messages in.
CHANNEL = HLE_SCRAPE_DEVS

# A module containing classes for handling unexpected tasks.
module UnexpectedTasks
  # A module for observing database changes.
  module DbObserver
    # A class for checking scraped tables.
    class ScrapedTablesChecker
      # Runs the scraped tables checker.
      #
      # @param options [Hash] A hash of options for the checker.
      # @option options [Boolean] :run Whether to run the checker.
      # @option options [Boolean] :check Whether to do some checking or debugging.
      # @option options [Boolean] :auto Whether to automatically run and check the checker.
      def self.run(**options)
        @_s_    = Storage.new

        # Configure Slack API.
        Slack.configure do |config|
          config.token = @_s_.slack
          raise 'Missing Slack API token!' unless config.token
        end

        manager = ScrapedTablesCheckerManager.new
        manager.run if options[:run] || options[:auto]
        manager.check if options[:check] || options[:auto]
      rescue StandardError => e
        # Notify Oleksii Kuts of the exception and print the stack trace.
        Slack::Web::Client.new.chat_postMessage(
          channel: OLEKSII_KUTS,
          text: "Scraped_DB_Tables_Checker EXCEPTION: #{e}",
          as_user: true)
        puts ['*'*77,  e.backtrace]
        exit 1
      end
    end
  end
end
