# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_0818: Started Scraping(#{options[:block]})!")
    Manager.new.scrape(options)
    Hamster.report(to: 'U04JS3K201J', message: "project_0818: Scraping Done(#{options[:block]})!")
  rescue Exception => e
    Manager.new.clear
    Hamster.report(to: 'U04JS3K201J', message: "project_0818:\n#{e.full_message}")
  end
end
