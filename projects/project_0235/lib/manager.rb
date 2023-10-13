# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager <  Hamster::Scraper
  
  MAIN_PAGE = "https://www.justice.gov/usao/pressreleases?page="

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @already_processed_links = @keeper.already_inserted_items('links')
    @inserted_tags = @keeper.already_inserted_items('tags')
  end

  def download
    page_no = 0
    while true
      main_response = @scraper.connect_to("#{MAIN_PAGE}#{page_no}")
      save_page(main_response,"outer_page_#{page_no + 1}","#{@keeper.run_id}")
      links,parsed_page = @parser.get_inner_links(main_response,'body')
      break if !(@already_processed_links && links).empty?
      links.each do |link|
        next if @already_processed_links.include? link
        inner_link_response =  @scraper.connect_to(link)
        file_name = Digest::MD5.hexdigest link
        save_page(inner_link_response,file_name,"#{@keeper.run_id}")
      end
      page_no += 1
    end
  end

  def store
    dowloaded_files = peon.give_list(subfolder: "#{@keeper.run_id}")
    dowloaded_files.each do |file|
      next unless file.include? "outer_page"
      outer_page_content = peon.give(subfolder: "#{@keeper.run_id}", file: file)
      inner_links = @parser.get_inner_links(outer_page_content,'links')
      inner_links.first.each do |link|
        next if @already_processed_links.include? link
        file_name  = Digest::MD5.hexdigest link
        inner_page_content = peon.give(subfolder: "#{@keeper.run_id}", file: "#{file_name}.gz") rescue next
        next if inner_page_content.include? 'Page not found'
        data_hash,tags = @parser.parse_data(inner_page_content,link,@keeper.run_id)
        @keeper.insert_data(data_hash,'USAOM') 
        tags_table_insertion(tags,link) unless tags.empty?
      end
    end
    @keeper.finish
  end

  private

  def tags_table_insertion(tags,link)
    tags.each do |tag|
      unless @inserted_tags.include? tag
        @keeper.insert_data(tag,'USAOMTags')
        @inserted_tags.push(tag)
      end
      id = @keeper.already_inserted_items('id',tag)
      @keeper.insert_data(id.first,'USAOMTALinks',link)
    end
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: file_name, subfolder: sub_folder
  end

end
