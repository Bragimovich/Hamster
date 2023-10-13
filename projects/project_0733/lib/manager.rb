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
    main_response = @scraper.get_main_response
    years = @parser.get_years(main_response.body)
    cookie_value = main_response.headers['set-cookie']
    years.each do |year|
      current_page = get_starting_value(year)
      while true
        if (current_page%5 ==0)
          main_response = @scraper.get_main_response
          cookie_value = main_response.headers['set-cookie']
        end
        post_response = @scraper.get_post_response(cookie_value,year,current_page)
        save_html(post_response,"page_#{current_page}","#{@keeper.run_id}/#{year}/")
        total_pages = @parser.get_total_pages(post_response.body)
        current_page += 1
        break if ((total_pages.nil?) || (current_page == total_pages))
      end
    end
  end

  def store
    processed_files = file_handling(processed_files,'r') rescue []
    years = peon.list(subfolder: "#{@keeper.run_id}/").reject{|e| e.include? 'txt'}
    years.each do |year|
      salarie_data = []
      salarie_md5 = []
      files = peon.list(subfolder: "#{@keeper.run_id}/#{year}")
      files.each do |file|
        next if (processed_files.include? file)
        page_body = peon.give(subfolder: "#{@keeper.run_id}/#{year}",file: file)
        data_array,md5_array = @parser.parse_data(page_body,year,@keeper.run_id)
        salarie_data << data_array
        salarie_md5 << md5_array
        if (salarie_data.flatten.count == 5000)
          salarie_data = salarie_data.flatten.reject{|e| e.empty?}
          salarie_md5 = salarie_md5.flatten.reject{|e| e.empty?}
          @keeper.insert_records(salarie_data)
          @keeper.update_touch_run_id(salarie_md5)
          salarie_data = []
          salarie_md5 = []
        end
        file_handling(file,'a')
      end
      salarie_data = salarie_data.flatten.reject{|e| e.empty?}
      salarie_md5 = salarie_md5.flatten.reject{|e| e.empty?}
      @keeper.insert_records(salarie_data)
      @keeper.update_touch_run_id(salarie_md5)
    end
    @keeper.mark_delete
    @keeper.finish
    FileUtils.rm_rf("#{storehouse}store/#{@keeper.run_id}")
  end

  private

  def get_starting_value(year)
    peon.list(subfolder: "#{@keeper.run_id}/#{year}/").map{|e| e.split('_').last.split('.').first.to_i}.sort.reverse.first rescue 0
  end

  def save_html(html,file_name,sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

  def file_handling(content,flag)
    list = []
    File.open("#{storehouse}store/#{@keeper.run_id}/links.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

end
