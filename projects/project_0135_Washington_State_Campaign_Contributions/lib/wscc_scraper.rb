# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize(type=nil)
    super
    peon = Peon.new(storehouse)
    if type.nil?
      get_all_files
    elsif [:contribute, :expenditures, :candidate].include?(type.to_sym)
      download_csv(type.to_sym)
    else
      log("Not this type: #{type}")
    end
  end

  def get_all_files
    [:contribute, :expenditures, :candidate].each do |type|
      download_csv(type)
    end

  end

  def download_csv(type=:contribute)
    log("Downloading #{type}...", color='yellow')
    csv_contribute = csv_url[type]
    connect_to(csv_contribute, method: :get_file, filename: storehouse+"trash/" + filename[type])
    skip_rows_filename = "#{storehouse}/skip_rows"
    File.open(skip_rows_filename, 'w') { |file| file.write('0') }
  end

  private

  def csv_url
    {
      :contribute => "https://data.wa.gov/api/views/kv7h-kjye/rows.csv?accessType=DOWNLOAD",
      :expenditures => "https://data.wa.gov/api/views/tijg-9zyp/rows.csv?accessType=DOWNLOAD",
      :candidate => "https://data.wa.gov/api/views/iz23-7xxj/rows.csv?accessType=DOWNLOAD"
    }
  end

  def filename
    {
      :contribute => "Contributions_to_Candidates_and_Political_Committees.csv",
      :expenditures => "Expenditures_by_Candidates_and_Political_Committees.csv",
      :candidate => "Candidate_and_Committee_Registrations.csv",
    }
  end


end
