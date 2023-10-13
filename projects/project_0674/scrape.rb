# frozen_string_literal: true
require_relative '../project_0674/lib/manager'
def scrape(options)
  begin
    Hamster.report(to: 'Mashal Ahmad', message: "project_0674: Parsing and storing Started!")
    manager = Manager.new
    manager.parse_store
    Hamster.report(to: 'Mashal Ahmad', message: "project_0674: Parsing and storing Done!")
    rescue Exception => e
      Hamster.report(to: 'Mashal Ahmad', message: "project_0674:\n#{e.full_message}")
  end
end