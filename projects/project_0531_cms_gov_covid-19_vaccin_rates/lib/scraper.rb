# frozen_string_literal: true

require_relative '../models/cms_gov_covid_vax_rates'

class Scrape < Hamster::Scraper

  date = Time.now.strftime('%Y-%m').gsub('-', '_')
  FILE_NAME = "cms_gov_covid-19_vaccine_rates_#{date}"
  URL =
    'https://data.cms.gov/provider-data/api/1/datastore/query/avax-cv19/0?offset=0&count=true&results=true&schema=true&keys=true&format=json&rowIds=false'
  MAIN_TABLE = CmsGovCovidVaxRateV2

  def download
    peon.move_all_to_trash

    request =
      connect_to(URL)
    if request.status == 200
      peon.put(
        file: FILE_NAME,
        content: request.body
      )
    else
      Hamster.report(to: 'Yunus Ganiyev', message: 'Bad response')
    end
  rescue => e
    puts e.full_message
  end

  def parse_file
    file = JSON.parse(peon.give(file: FILE_NAME))
    file = file['results'].map { |el| el.transform_keys(&:to_sym) }
    date = Date.strptime(file.first[:date_vaccination_data_last_updated].gsub('.', '/'), '%m/%d/%Y')

    if MAIN_TABLE.maximum('date_vax_data_last_updated') >= date
      message = 'No new data for `project_0531_cms_gov_covid-19_vaccine_rates_v2`'
      Hamster.report(to: 'Yunus Ganiyev', message: message)
      raise message
    end

    file.each do |el|
      main = MAIN_TABLE.new

      main.state = el[:state]
      main.pct_of_residents_who_completed_primary_vaccination_series =
        el[:percent_of_residents_who_completed_primary_vaccination_series].to_f
      main.pct_of_staff_who_completed_primary_vaccination_series =
        el[:percent_of_staff_who_completed_primary_vaccination_series].to_f
      main.pct_of_residents_who_are_up_to_date_on_their_vaccines =
        el[:percent_of_residents_who_are_uptodate_on_their_vaccines].to_f
      main.pct_of_staff_who_are_up_to_date_on_their_vaccines =
        el[:percent_of_staff_who_are_uptodate_on_their_vaccines].to_f
      main.date_vax_data_last_updated = date

      begin
        main.save
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end
end
