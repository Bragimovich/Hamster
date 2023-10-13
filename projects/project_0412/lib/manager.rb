require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper     = Keeper.new
    @parser     = Parser.new
    @scraper    = Scraper.new
    @sub_folder = "Run_ID_#{@keeper.run_id}"
    @already_inserted_links       = @keeper.get_inserted_links
  end

  def run
    unless (keeper.download_status(keeper.run_id)[0].to_s == "true")
      download
    else
      parse
      parse_brief_page
    end
  end

  private

  def download
    page_number = 0
    while true
      outer_response = scraper.get_page(page_number)
      links = parser.get_inner_links(outer_response.body) 
      break if links.empty?
      links.each do |sub_link|
        inner_page_url = "https://www.eeoc.gov" + sub_link
        next if already_inserted_links.include? inner_page_url
        case_information = Digest::MD5.hexdigest inner_page_url
        inner_response = scraper.inner_page(inner_page_url)
        save_file(inner_response, case_information, "#{sub_folder}/brief")
        download_details_page(inner_response.body)
      end
      page_number += 1
    end
    keeper.mark_download_status(keeper.run_id)
    if (keeper.download_status(keeper.run_id)[0].to_s == "true")
      parse
      parse_brief_page
    end
  end

  def parse
    data_array = []
    downloaded_files = peon.give_list(subfolder: "#{sub_folder}/brief")
    downloaded_files.each do |file_name|
      file_content_brief = peon.give(subfolder: "#{sub_folder}/brief", file: file_name)
      brief_data_hash = parser.get_brief_data(file_content_brief, already_inserted_links, keeper.run_id)
      data_array.append(brief_data_hash) unless brief_data_hash.nil?
    end
    keeper.make_insertions(data_array, "EcocBriefs")
  end

  def parse_brief_page
    downloaded_files = peon.list(subfolder: "#{sub_folder}/detail_pdfs")
    deal_with_parsing(downloaded_files, 'pdf_file')
    downloaded_files = peon.list(subfolder: "#{sub_folder}/detail_html")
    deal_with_parsing(downloaded_files, 'html_file')
    downloaded_files = peon.list(subfolder: "#{sub_folder}/detail_text")
    deal_with_parsing(downloaded_files, 'text_file')
    keeper.mark_dirty
  end

  def deal_with_parsing(downloaded_files, file_type)
    false_links = ["https://www.eeoc.gov/sites/default/files/migrated_files/eeoc/litigation/briefs/hesco_.txt", "https://www.eeoc.gov/sites/default/files/migrated_files/eeoc/litigation/briefs/general_mills.html"]
    parent_data = keeper.get_parent_data
    if file_type == "pdf_file"
      downloaded_files = keeper.get_download_files
      downloaded_files = downloaded_files.map{|u|  Digest::MD5.hexdigest u}.map{|u| u = u + ".pdf"}
    end
    downloaded_files.each do |file_name|
      parties_hash, brief_data_hash = fetch_case_info(file_name, file_type)
      next if parties_hash.nil? and brief_data_hash.nil?

      parents = parent_data.select {|r| file_name.start_with? Digest::MD5.hexdigest r[0]}
      commission_hashes_array = []
      party_hashes_array = []
      parents.each do |record|
        url =  record[0] unless record[0].nil?
        brief_data_hash.each do |data_array|
          data_array.each do |data|
            data_hash = parser.complete_record(data, record, url, keeper.run_id)
            commission_hashes_array.append(data_hash) unless data_hash.nil?
          end
        end
        parties_hash.each do |party|
          next if false_links.include? url
          data_hash = parser.complete_record(party, record, url, keeper.run_id)
          party_hashes_array << data_hash
        end
      end
      keeper.make_insertions(party_hashes_array, "EeocParties")
      keeper.make_insertions(commission_hashes_array, "EeocComission")
    end
    keeper.finish
  end

  def fetch_case_info(file_name, type)
    if type == "pdf_file"
      parties_hash, brief_data_hash = parser.processed_pdf_files("#{storehouse}store/#{sub_folder}/detail_pdfs/#{file_name}")
    elsif type == "html_file"
      file_content_brief = peon.give(subfolder: "#{sub_folder}/detail_html", file: file_name)
      parties_hash, brief_data_hash = parser.processed_html_files(file_content_brief)
    else
      file_content_brief = peon.give(subfolder: "#{sub_folder}/detail_text", file: file_name)
      parties_hash, brief_data_hash = parser.processed_text_files(file_content_brief)
    end
    [parties_hash, brief_data_hash]
  end

  def download_details_page(html)
    link = parser.fetch_link_for_inner_page(html)
    details_url = "https://www.eeoc.gov" + link
    return if (details_url.end_with? ".txt" or details_url.end_with? ".html")
    details_response = scraper.inner_page(details_url)
    file_name_detail = Digest::MD5.hexdigest details_url
    if details_url.end_with? '.txt'
      save_file(details_response, file_name_detail, "#{sub_folder}/detail_text")
    elsif details_url.end_with? '.html'
      save_file(details_response, file_name_detail, "#{sub_folder}/detail_html")
    elsif details_url.end_with? '.pdf'
      save_pdf(details_response.body, file_name_detail, "detail_pdfs")
    end
  end

  def save_pdf(content, file_name, dist_num)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}/detail_pdfs"
    pdf_storage_path = "#{storehouse}store/#{sub_folder}/detail_pdfs/#{file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(content, file_name, subfolder)
    peon.put content: content.body, file: file_name, subfolder: subfolder
  end

  attr_accessor :keeper, :parser, :sub_folder, :scraper, :already_inserted_links
end
