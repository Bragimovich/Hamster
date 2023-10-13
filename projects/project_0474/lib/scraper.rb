# frozen_string_literal: true

require 'zip'

class Scraper < Hamster::Scraper
  def download_csv
    connect_to(CSV_URL, method: :get_file, filename: storehouse+"store/" + "NYS_Attorney_Registrations.csv")
  end

  def clear
    name = Time.now.to_s.gsub(':', '-').split[0..1].join('.')
    folder = "#{storehouse}store/"
    zipfile_name = "#{storehouse}trash/#{name}.zip"
    Zip::File.open(zipfile_name, create: true) do |zip|
      peon.list.each do |filename|
        zip.add(filename, File.join(folder, filename))
      end
    end
    FileUtils.rm Dir["#{folder}*"]
  end
end
