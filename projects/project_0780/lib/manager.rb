# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
  end

  def download
    scraper.download_candidate_data
    scraper.download_nys_filer_file('Filers', 'filerslist', keeper.run_id)
    get_campaign_files
    get_fmt_files
  end

  def store
    extract_zip_files
    processed_files = file_handling(processed_files,'r') rescue []
    files = get_files('*.csv')
    files.each do |file|
      next if (processed_files.include? file)
      case
      when file.include?('cont')
        parser.parse_data(file, 'https://www.nyccfb.info/FTMSearch/Home/FTMSearch', keeper.run_id, 'cont')
      when file.include?('exp')
        parser.parse_data(file, 'https://www.nyccfb.info/FTMSearch/Home/FTMSearch', keeper.run_id, 'expend')
      when file.include?('inter')
        parser.parse_data(file, 'https://www.nyccfb.info/FTMSearch/Home/FTMSearch', keeper.run_id, 'inter')
      when file.include?('filer')
        parser.parse_filer_data(file, 'https://publicreporting.elections.ny.gov/', keeper.run_id, 'filer')
      else
        parser.parse_report_data(file, 'https://publicreporting.elections.ny.gov/', keeper.run_id, 'repo')
      end
      file_handling(file,'a')
    end
    store_candidate_data
    model_keys = ['cont','expend','inter','filer','repo','can']
    model_keys.each do |key|
      keeper.mark_delete(key)
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def get_files(file_type)
    Dir["#{storehouse}store/#{keeper.run_id}/**/#{file_type}"]
  end

  def store_candidate_data
    data_array = []
    md5_array = []
    files = Dir["#{storehouse}store/#{keeper.run_id}/candidate/**/*.gz"]
    files.each do |file|
      page_body = peon.give(subfolder: "#{file.split('/')[-4..-2].join('/')}", file: file.split('/').last)
      data_hash,md5_hash = parser.parse_candidate_data(page_body)
      data_array << data_hash
      md5_array << md5_hash
      if (data_array.count == 5000)
        data_array = data_array.flatten.reject{ |e| e.empty? }
        md5_array = md5_array.flatten.reject{ |e| e.empty? }
        keeper.insert_records(data_array.flatten, 'can')
        keeper.update_touched_run_id(md5_array.flatten, 'can')
        data_array = []
        md5_array = []
      end
    end
    data_array = data_array.flatten.reject{ |e| e.empty? }
    md5_array = md5_array.flatten.reject{ |e| e.empty? }
    keeper.insert_records(data_array.flatten, 'can')
    keeper.update_touched_run_id(md5_array.flatten, 'can')
  end

  def get_fmt_files
    count = 0
    while true
      break if (count > 10)
      files = Dir["#{storehouse}store/#{keeper.run_id}/*.csv"]
      if (files.count < 3)
        scraper.start_browser
        scraper.download_fmt_files('https://www.nyccfb.info/FTMSearch/Candidates/Expenditures?ec=2025%2C2023%2C2022%2C2021%2C2018%2C2017%2C2013%2C2009%2C2005%2C2003%2C2001%2C1997%2C1993%2C1991%2C1989%2C2020A%2C2020B%2C2019%2C2016%2C2015%2C2011%2C2010%2C2008%2C2007%2C1999%2C1996%2C1994%2C2021C%2C2021B%2C2021A%2C2020C%2C2019B%2C2019A%2C2017A%2C2016A%2C2015A%2C2013A%2C2012A%2C2010B%2C2010A%2C2009B%2C2009A%2C2008A%2C2007B%2C2007A%2C2005A%2C2003A%2C2002A%2C2001A%2C1999A%2C1997A%2C1996A%2C1994A%2C1993A%2C1991B%2C1991A%2C1990A%2C2021T%2C2017T%2C2013T%2C2010V%2C2010U%2C2009T%2C2009V%2C2009U%2C2005T%2C2003T%2C2003U%2C2001T%2C2019T', 'CFB', 'expenditures', keeper.run_id)
        scraper.download_fmt_files('https://www.nyccfb.info/FTMSearch/Candidates/Intermediaries?ec=2025%2C2023%2C2022%2C2021%2C2018%2C2017%2C2013%2C2009%2C2005%2C2003%2C2001%2C1997%2C1993%2C1991%2C1989%2C2020A%2C2020B%2C2019%2C2016%2C2015%2C2011%2C2010%2C2008%2C2007%2C1999%2C1996%2C1994%2C2021C%2C2021B%2C2021A%2C2020C%2C2019B%2C2019A%2C2017A%2C2016A%2C2015A%2C2013A%2C2012A%2C2010B%2C2010A%2C2009B%2C2009A%2C2008A%2C2007B%2C2007A%2C2005A%2C2003A%2C2002A%2C2001A%2C1999A%2C1997A%2C1996A%2C1994A%2C1993A%2C1991B%2C1991A%2C1990A%2C2021T%2C2017T%2C2013T%2C2010V%2C2010U%2C2009T%2C2009V%2C2009U%2C2005T%2C2003T%2C2003U%2C2001T%2C2019T', 'CFB', 'intermediaries', keeper.run_id)
        scraper.close_browser
      else
        break
      end
      count += 1
    end
  end

  def get_campaign_files
    count = 0
    while true
      break if (count > 10)
      files = Dir["#{storehouse}store/#{keeper.run_id}/*.zip"]
      if (files.count < 48)
        scraper.download_nys_compaign_files(keeper.run_id)
      else
        break
      end
      count += 1
    end
  end

  def extract_zip_files
    zip_files_path = get_files('*.zip')
    zip_files_path.each do |file_path|
      dest_dir = file_path.gsub('.zip','')
      FileUtils.mkdir_p(dest_dir)
      Zip::File.open(file_path) do |zip_file|
        zip_file.each do |entry|
          output_path = File.join(dest_dir, entry.name)
          zip_file.extract(entry, output_path) { true }
        end
      end
    end
  end

  def file_handling(content,flag)
    list = []
    File.open("#{storehouse}store/#{@keeper.run_id}/links.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

end
