# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = DelawareVoterRegistrationsParser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    main_page = scraper.connect_page
    get_link_year = parser.get_link_year(main_page)
    get_page = scraper.connect_page(get_link_year)
    save_page(main_page,'delaware_voter_1_outer_Page',"#{keeper.run_id}")
    save_page(get_page,'delaware_voter_0_outer_Page',"#{keeper.run_id}")
    pdf_links = parser.get_pdf_link(main_page.body)
    pdf_links = (pdf_links << parser.get_pdf_link(get_page.body)).flatten
    pdf_links.each do |link|
      save_link(link)
    end
  end

  def store
    stored_files = peon.give_list(subfolder: "#{keeper.run_id}")
    stored_files.each do |file_name|
      outer_page_info = peon.give(subfolder: "#{keeper.run_id}", file: file_name)
      pdf_links = parser.get_pdf_link(outer_page_info)
      pdf_links.each do |link|
        file_name = Digest::MD5.hexdigest link
        path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.pdf"
        voter_info = parser.get_pdf_data(path,keeper.run_id, link)
        keeper.insert_records(voter_info)
      end
    end
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser , :scraper

  def save_link(link)

    pdf_body = scraper.connect_page(link)
    file_name = Digest::MD5.hexdigest link
    save_zip(pdf_body.body, file_name)
  end

  def save_zip(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.pdf"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end
  
  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end
end
