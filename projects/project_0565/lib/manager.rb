require_relative'scraper'
require_relative'parser'
require_relative'keeper'
require_relative'pdf_parser'

class Manager < Hamster::Scraper

  CASES_SUB_FOLDER = 'vt_sc_cases'
  def initialize(**options)
    super
    @keeper = Keeper.new
    @scraper = Scraper.new
    @parser = Parser.new
    @pdf_parser = PdfParser.new
  end

  def download
    @year = 2016
    count = 0
    info_hash = {}
    case_info_hash = []
    party_type_array = ["Plaintiff-Appellant", "Defendant-Appellee"]
    landing_page = @scraper.fetch_main_page
    return if landing_page.nil?
    document = @parser.get_data_from_sub_page(landing_page)
    (@year..Time.now.year).each do |year|
      j = Time.now.year - year
      inner_table = document.css("div.field--name-field-accordions").css("div.field__item").css("div.paragraph")[j].css("div.accordion__body").css("div.clearfix").css("div.accordion__content").css("div.clearfix").css("tbody tr")
      inner_table.each do |row|
        begin
          if row.css("td[3]")&.text.empty? == false
            info_hash = @parser.fetch_case_info_hash(row)
            case_name = info_hash['case_name'].gsub(/[\n\t]/, " ").squeeze("").strip.split("  ").first
            check_data_exists = @keeper.check_record_exits(case_name)
            next if check_data_exists.present?
            link = info_hash['link']
            info_hash['source_link'] = @scraper.get_file_path(link)
            case_ids = @pdf_parser.remove_extra_space_case_id(info_hash['case_id'])
            case_ids.each do |case_id|
              pdf_file = @scraper.save_pdf_file(link, year, case_id)
              pdf_paths = Dir["#{storehouse}/store/pdfs/#{year}/*.pdf"]
              pdf_path = pdf_paths.select{|file| file.include? case_id}.first
              reader = PDF::Reader.new(open(pdf_path))
              party_type_array.each do |type|
                info_hash['pdf_data'] = @parser.fetch_data_from_pdf(reader, type, info_hash['source_link'])
                info_hash['aws_url'] = info_hash['pdf_data'].nil? || info_hash['pdf_data'].empty? ? '' : @keeper.save_files_to_aws(info_hash['source_link'],case_id)
                case_info_hash << info_hash
                @keeper.parse_data(case_info_hash, type, count, case_id)
                case_info_hash = []
                count = count + 1
              end
              count = 0
              File.delete(pdf_path)
              pdf_paths = []
            end
          end
        rescue
          logger.error 'some error in this file'
        end
      end
    end
  end 
end
