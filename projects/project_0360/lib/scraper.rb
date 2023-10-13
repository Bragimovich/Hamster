# frozen_string_literal: true

require_relative 'parser'
require_relative 'connector'
class Scraper < Hamster::Scraper
  HOST = 'https://cfis.wi.gov'
  BASE_URL = "#{HOST}/Public/Registration.aspx"
  RECEIPT_URL = "#{HOST}/Public/ReceiptList.aspx"
  EXPENSE_URL = "#{HOST}/Public/ExpenseList.aspx"
  REGISTRANT_URL = "#{HOST}/Public/RegistrantList.aspx"

  def initialize
    super
    @connector = WiInmateConnector.new(BASE_URL)
    @parser = Parser.new
  end

  def receipt_list(year)
    retry_count  = 0
    cur_range    = nil
    rec_acpt_url = 'https://cfis.wi.gov/Public/PublicNote.aspx?Page=ReceiptList'
    logger.info "Downloading receipt list -> year: #{year}"
    begin
      response = @connector.do_connect(rec_acpt_url)
      form_data = @parser.hidden_field_data(response.body)
      form_data.merge!('btnContinue.x' => rand(3..80), 'btnContinue.y' => rand(2..20))
      response = @connector.do_connect(rec_acpt_url, method: :post, data: form_data)

      year_form_data = @parser.receipt_year_form_data(response.body, year)
      response = @connector.do_connect(RECEIPT_URL, method: :post, data: year_form_data)

      search_form_data = @parser.receipt_search_form_data(response.body, year)
      response = @connector.do_connect(RECEIPT_URL, method: :post, data: search_form_data)

      range_list = @parser.range_list(response.body)
      logger.info "#{year} range list: #{range_list}"
      if cur_range
        cur_index  = range_list.index(cur_range)
        range_list = range_list[cur_index..]
      end
      range_list.each do |range|
        logger.info "Downloading receipt list -> year: #{year}, range: #{range}"
        cur_range = range
        file_path = "#{store_file_path(year)}/receipt_#{range}.csv"
        csv_download_data = @parser.receipt_csv_download_data(response.body, year, range)
        csv_response = @connector.do_connect(RECEIPT_URL, method: :post, data: csv_download_data)
        store_data(file_path, csv_response.body)
      end
    rescue => e
      logger.info e.full_message

      raise e if retry_count > 3

      retry_count += 1
      retry
    end
  end

  def expense_list(year)
    logger.info "Downloading expense list -> year: #{year}"
    exp_acpt_url = 'https://cfis.wi.gov/Public/PublicNote.aspx?Page=ExpenseList'
    retry_count  = 0
    begin
      response = @connector.do_connect(exp_acpt_url)
      form_data = @parser.hidden_field_data(response.body)
      form_data.merge!('btnContinue.x' => rand(3..80), 'btnContinue.y' => rand(2..20))
      response = @connector.do_connect(exp_acpt_url, method: :post, data: form_data)

      year_form_data = @parser.expense_year_form_data(response.body, year)
      response = @connector.do_connect(EXPENSE_URL, method: :post, data: year_form_data)

      search_form_data = @parser.expense_search_form_data(response.body, year)
      response = @connector.do_connect(EXPENSE_URL, method: :post, data: search_form_data)

      file_path = "#{store_file_path(year)}/expense.csv"
      csv_download_data = @parser.expense_csv_download_data(response.body, year)
      response = @connector.do_connect(EXPENSE_URL, method: :post, data: csv_download_data)
      store_data(file_path, response.body)
    rescue => e
      logger.info e.full_message

      raise e if retry_count > 3

      retry_count += 1
      retry
    end
  end

  def registrant_list(registrant_type)
    logger.info "\nDownloading registrant list -> type: #{registrant_type}"
    reg_acpt_url = 'https://cfis.wi.gov/Public/PublicNote.aspx?Page=RegistrantList'
    retry_count  = 0
    begin
      response = @connector.do_connect(reg_acpt_url)
      form_data = @parser.hidden_field_data(response.body)
      form_data.merge!('btnContinue.x' => rand(3..80), 'btnContinue.y' => rand(2..20))
      response = @connector.do_connect(reg_acpt_url, method: :post, data: form_data)

      search_form_data = @parser.registrant_search_form_data(response.body, registrant_type)
      response         = @connector.do_connect(REGISTRANT_URL, method: :post, data: search_form_data)
      page_info_text   = @parser.parse_page_info(response.body)

      return unless page_info_text

      page_count       = page_info(page_info_text)[2].to_i
      page             = 1
      logger.info "Scraped registrant list -> type: #{registrant_type}, page_count: #{page_count}"
      loop do
        page_info_text = @parser.parse_page_info(response.body)
        logger.debug "\n #{'-*-'*20} #{page_info_text}" 

        registrant_list = @parser.registrant_list(response.body)
        logger.debug "\nScraped registrant list: #{registrant_list}"

        registrant_list.each do |data|
          file_path = "#{store_pdf_file_path(registrant_type[0])}/#{data[0]}.pdf"

          next if File.exist?(file_path)

          pdf_form_data = @parser.registrant_pdf_download_data(response.body, registrant_type[0], data[1])
          pdf_response  = @connector.do_connect(REGISTRANT_URL, method: :post, data: pdf_form_data)
          logger.debug "Downloaded pdf file: #{data[0]}.pdf"
          store_data(file_path, pdf_response.body)
        end

        break if page == page_count

        page += 1
        page_params = @parser.registrant_page_params(response.body, registrant_type[0], page)
        response = @connector.do_connect(REGISTRANT_URL, method: :post, data: page_params)
      end
    rescue => e
      logger.info "Raised error when downloading pdf files in page: #{page}"
      logger.info e.full_message

      raise e if retry_count > 3

      retry_count += 1
      @connector.update_proxy_and_cookie
      retry
    end
  end

  private
  
  def store_data(file_path, data)
    File.open(file_path, 'w+') do |f|
      f.puts(data)
    end
  end

  def store_file_path(subfolder)
    store_path = "#{storehouse}store/#{subfolder}"
    FileUtils.mkdir_p(store_path)
    store_path
  end

  def store_pdf_file_path(subfolder)
    store_path = "#{storehouse}store/registrant/#{subfolder}"
    FileUtils.mkdir_p(store_path)
    store_path
  end

  def page_info(text)
    text.match(/page\s(\d+)\sof\s(\d+),/)
  end
end

