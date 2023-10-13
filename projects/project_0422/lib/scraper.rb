# frozen_string_literal: true

require 'zip'

class Scraper < Hamster::Scraper
  def initialize(args)
    super
  end

  def get_source(url)
    connect_to(url: url)
  end

# ================== ATTENTION !!! ===============================
# connect_to for some reason often download only 20 MB
# of target file without any error.
# unzip method can't extract files and causes an error
# to download all 800+ MB you need to repeat downloading
# until unzip will be able to extract all data
  def download(file)
    flag = false
    until flag do         # download and unzip until it will be done
      flag = true
      begin
        connect_to(URL + file, method: :get_file, filename: storehouse+"store/" + file)
        unzip
      rescue
        flag = false
      end
    end
  end

  def unzip
    path = storehouse + 'store/'
    trash_path = storehouse + 'trash/'
    peon.list.each do |zip|
      Zip::File.open(path + zip) do |zip_file|
        zip_file.each do |f|
          if (!f.name.downcase.include?('fileheader') && !f.name.include?('.pdf'))
            zip_file.extract(f, path + f.name) unless File.exist?(path + f.name)
          end
        end
      end
      FileUtils.mkdir_p trash_path
      FileUtils.mv(path + zip, trash_path + zip)
    end
  end

  def file_exist?(file)
    Dir[storehouse + "trash/*"].include?(storehouse + "trash/" + file)
  end

  def clear
    FileUtils.rm Dir[storehouse + "store/*"]
  end
end
