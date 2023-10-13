# frozen_string_literal: true

class SlackReporter
  def self.report(message:)
    Hamster.report(to: 'U055UHN4Z8S', message: message)
  rescue
  end
end
