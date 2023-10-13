# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper = Scraper.new
  end

  def download
    report_ids = ['41','81']
    report_ids.each do |report_id|
      page = get_start_page(report_id)
      while true
        response = @scraper.post_response(report_id,page)
        total_pages = @parser.get_total_pages(response.body) rescue nil
        save_page(response,"page_#{page}","#{@keeper.run_id}/#{report_id}/") unless total_pages.nil?
        page += 1
        break if (page > total_pages) unless total_pages.nil?
      end
    end
  end

  def store
    store_district_data
    store_college_data
    @keeper.mark_delete('KsSal')
    @keeper.mark_delete('KsCcSal')
    @keeper.finish
    FileUtils.rm_rf("#{storehouse}store/#{@keeper.run_id}")
  end

  private

  def store_district_data
    files = peon.list(subfolder: "#{@keeper.run_id}/41")
    files.each do |file|
      page_body = peon.give(subfolder: "#{@keeper.run_id}/41",file: file)
      data_array,md5_array = @parser.parse_district_data(page_body,@keeper.run_id)
      @keeper.insert_records(data_array.flatten,'KsSal')
      @keeper.update_touch_run_id(md5_array,'KsSal')
    end
  end

  def store_college_data
    files = peon.list(subfolder: "#{@keeper.run_id}/81")
    files.each do |file|
      page_body = peon.give(subfolder: "#{@keeper.run_id}/81",file: file)
      data_array,md5_array = @parser.parse_college_data(page_body,@keeper.run_id)
      @keeper.insert_records(data_array.flatten,'KsCcSal')
      @keeper.update_touch_run_id(md5_array,'KsCcSal')
    end
  end

  def save_page(html,file_name,sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

  def get_start_page(report_id)
    peon.list(subfolder: "#{@keeper.run_id}/#{report_id}/").map{|e| e.split('_').last.gsub('.gz','').to_i}.sort.last rescue 1
  end

end
