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
    @s3         = AwsS3.new(bucket_key = :us_court)
  end

  def run
    (keeper.download_status(keeper.run_id)[0].to_s == "true") ? store : download
  end

  private
  
  def download
    years = ('2016'..Date.today.year.to_s).map(&:to_s).reverse
    years.each_with_index do |year, index|
      response = scraper.get_main_page
      cookie = response['set-cookie']
      __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR = parser.required_values(response)
      response = scraper.get_page(index, __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR, cookie)
      save_file(response, "main_page", "#{sub_folder}/#{year}/page_no_1")
      get_pdfs(response, 1, year)
      pagination(response, year, cookie)
    end
    keeper.mark_download_status(keeper.run_id)
  end

  def store
    years = ('2016'..Date.today.year.to_s).map(&:to_s).reverse
    years.each do |year|
      pages = peon.list(subfolder: "#{sub_folder}/#{year}")
      pages.each do |page|
        main_page = peon.give(subfolder: "#{sub_folder}/#{year}/#{page}", file: "main_page")
        date_array, title_array, links_array = parser.get_title(main_page)
        links_array.each_with_index do |link, index|
          file_name = Digest::MD5.hexdigest link
          path = "#{storehouse}store/#{sub_folder}/#{year}/#{page}/#{file_name}.pdf"
          aws_file = peon.give(subfolder: "#{sub_folder}/#{year}/#{page}", file: file_name)
          case_info, case_consolidations, case_pdfs_on_aws, case_relations_info_pdf, case_party_attorney, case_party = parser.pdf_parser(path, date_array[index], title_array[index], link, keeper.run_id, s3, aws_file)
          next if case_info.nil?
          keeper.make_insertions(case_info, case_consolidations, case_pdfs_on_aws, case_relations_info_pdf, case_party_attorney, case_party)
          info_del, consolidation_del, aws_del, attorney_del, lawyer_del = get_md5_hash(case_info, case_consolidations, case_pdfs_on_aws, case_party_attorney, case_party)
          keeper.update_touched_run_id(info_del, consolidation_del, aws_del, attorney_del, lawyer_del)
        end
      end
    end
    keeper.mark_deleted
    keeper.finish
  end

  def get_md5_hash(info_array, consolidation_array, pdf_aws, attorney, lawyer)
    [info_array.map{ |e| e[:md5_hash]}, consolidation_array.map{ |e| e[:md5_hash] }, pdf_aws.map{ |e| e[:md5_hash]}, attorney.map{ |e| e[:md5_hash]}, lawyer.map{ |e| e[:md5_hash]}]
  end

  def pagination(response, year, cookie)
    page_no = 1
    page_response = parser.parse_body(response.body)
    total_pages   = parser.get_total_pages(page_response)
    loop do
      __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR = parser.get_inner_values(response)
      response = scraper.get_inner_page(page_no, __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR, cookie)
      page_no += 1
      save_file(response, "main_page", "#{sub_folder}/#{year}/page_no_#{page_no}")
      get_pdfs(response, page_no, year)
      break if page_no == total_pages
    end
  end

  def get_pdfs(response, page_no, year)
    links = parser.get_links(response)
    links.each do |link|
      pdf_response = scraper.get_pdfs(link)
      file_name = Digest::MD5.hexdigest link
      save_pdf(pdf_response.body, file_name, "#{sub_folder}/#{year}/page_no_#{page_no}")
      save_file(pdf_response, file_name, "#{sub_folder}/#{year}/page_no_#{page_no}")
    end
  end

  def save_pdf(content, file_name, sub_folder)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}"
    pdf_storage_path = "#{storehouse}store/#{sub_folder}/#{file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(html, file_name , subfolder)
    peon.put content: html.body, file: file_name, subfolder: subfolder
  end

  attr_accessor :keeper, :parser, :sub_folder, :scraper, :s3
end
