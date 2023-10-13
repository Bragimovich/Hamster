# frozen_string_literal: true

require_relative '../models/cms_gov_covid_vax_rates'

class Scrape < Hamster::Scraper

  date = Time.now.strftime('%Y-%m').gsub('-', '_')
  FILE_NAME = "cms_gov_covid-19_vaccin_rates_#{date}"
  URL = 'https://data.cms.gov/provider-data/api/1/datastore/query/avax-cv19/0?offset=0&count=true&results=true&schema=true&keys=true&format=json&rowIds=false'
  MAIN_TABLE = CmsGovCovidVaxRate

  def download
    request =
      connect_to(URL)
    if request.status == 200
      peon.put(
        file: FILE_NAME,
        content: request.body
      )
    else
      Hamster.report(to: 'Yunus Ganiyev', message: 'Bad response', use: :both)
    end
  end

  def parse_file
    file = JSON.parse(peon.give(file: FILE_NAME))
    file = file['results'].map { |el| el.transform_keys(&:to_sym) }

    date = Date.strptime(file.first[:date_vaccination_data_last_updated].gsub('.', '/'), '%m/%d/%Y')

    if MAIN_TABLE.maximum('vax_data_updated_on') >= date
      message = 'No new data for `project_0137_cms_gov_covid-19_vaccin_rates`'
      Hamster.report(to: 'Yunus Ganiyev', message: message)
      raise message
    end

    file.each do |el|
      main = MAIN_TABLE.new

      main.state = el[:state]
      main.pct_vaxed_residents = el[:percent_vaccinated_residents].to_f
      main.pct_vaxed_healthcare_personnel = el[:percent_vaccinated_healthcare_personnel].to_f
      main.vax_data_updated_on = date

      begin
        main.save
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end
end
