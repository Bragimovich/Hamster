# frozen_string_literal: true

require 'zip'

class Scraper < Hamster::Scraper
  def clear
    name = Time.now.to_s.gsub(':', '-').split[0..1].join(' ')
    folder = "#{storehouse}store/"
    zipfile_name = "#{storehouse}trash/#{name}.zip"
    Zip::File.open(zipfile_name, create: true) do |zip|
      peon.list.each do |filename|
        zip.add(filename, File.join(folder, filename))
      end
    end
    FileUtils.rm Dir["#{folder}*"]
  end

  def clear_csv(filename)
    name = Time.now.to_s.gsub(':', '-').split[0..1].join(' ')
    folder = "#{storehouse}store/"
    zipfile_name = "#{storehouse}trash/#{filename}__#{name}.zip"
    Zip::File.open(zipfile_name, create: true) do |zip|
      zip.add(filename, File.join(folder, filename))
    end
    FileUtils.rm Dir["#{folder}#{filename}"]
  end

  def store_to_csv(source, file_name)
    return nil if source == ERROR
    path = "#{storehouse}store/#{file_name}"
    CSV.open(path, 'a') do |csv|
      source.each do |record|
        csv << record.values
      end
    end
  end

  def get_source(url)
    res = connect_to(url: url, headers: HEADERS)
    Hamster.report to: 'U03F2H0PB2T', message: "courtlistener " if res.status != 200
    res
  end
end
