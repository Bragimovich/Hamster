# frozen_string_literal: true

require_relative '../lib/connect'
require_relative '../lib/scraper'
require_relative '../lib/keeper'
require 'zip'

class Manager < Hamster::Harvester
  def initialize(options)
    super
    @keeper = Keeper.new
  end

  def download
    year_arr = (2012..(Time.now).strftime("%Y").split('').join.to_i).map {|time| time}
    scraper = Scraper.new
    scraper.main_page
    year_arr.each do |year|
      scraper.save_file(year)
    end
  end

  def store
    Dir.glob(storehouse + "store/*").each do |file|
      count = 1
      doc = CSV.foreach(file, headers: false, col_sep: ",")
      headers = doc.first.map {|el| el.strip}
      row_count = doc.count
      doc.each_with_index do |row, index|
        next if index == 0
        hash = Hash.new
        row.each_with_index do |value, row_index|
          hash[headers[row_index]] = value
        end
        @keeper.year = file.split('/').last.split('_').last.to_i if index == 1
        @keeper.enrollment(hash)
        if count == 1000 || index == row_count - 1
          @keeper.store_enrollment
          count = 0
        end
        count += 1
      end
      puts ("file end").green
    end
    @keeper.update_delete_status
    clear
    @keeper.finish
  end

  def clear
    name = "employee_#{Time.now.strftime("%Y_%m_%d")}"
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
