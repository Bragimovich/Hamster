require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/csv_parser'
require_relative '../lib/pdf_parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester
  def initialize(options = nil)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @csv_parser = CsvParser.new
    @pdf_parser = PdfParser.new
    @keeper = Keeper.new
  end

  def scrape(options)
    (2016..Date.today.year).each do |year|      
      @scraper.receipt_list(year) # Downloading receipt CSV files      
      @scraper.expense_list(year) # Downloading expense CSV files
      store(year) # Storing all CSV files
    end
    @keeper.finish
  end

  def scrape_pdfs(options)
    type_list = []
    if options[:first_block]
      type_list = [['State Candidate','01']]
    else
      type_list = [
        ['Political Party','03'],
        ['Legislative Campaign Committee','04'],
        ['PAC','05'],
        ['Recall','06'],
        ['Referendum','07'],
        ['Sponsoring Organization','08'],
        ['Conduit','09'],
        ['Ethics Commission','10'],
        ['Independent Expenditure Committee','11'],
        ['Unregistered Express Advocacy','12']
       ]
    end
    type_list.each do |reg_type|
      @scraper.registrant_list(reg_type)
      store_pdfs(reg_type[0])
    end
    @keeper.finish
  end

  def store(year)
    files = Dir["#{storehouse}store/#{year}/*"]
    files.each do |file_path|
      if file_path.include?('expense')
        store_expense(file_path)
      elsif file_path.include?('receipt')
        store_receipt(file_path)
      end
    end
  end

  def store_pdfs(reg_type)
    logger.info "Storing pdf data, Registrant Type: #{reg_type}"
    files = Dir["#{storehouse}store/registrant/#{reg_type}/*"]
    files.each do |file_path|
      begin
        hash_data = @pdf_parser.parse_pdf(file_path, reg_type)
        @keeper.store_registrant(hash_data)
        File.delete(file_path) if File.exist?(file_path)
      rescue => e
        logger.info file_path
        logger.info e.full_message

        next
      end
    end
    @keeper.flush_registrant
  end

  def store_receipt(file_path)
    receipt_data = @csv_parser.parse_receipt_data(file_path)
    logger.info "Storing receipt csv file: #{file_path}, count: #{receipt_data.count}"
    receipt_data.each do |data|
      @keeper.store_receipt(data)
    end
    File.delete(file_path) if File.exist?(file_path)
    @keeper.flush_receipt
  end

  def store_expense(file_path)
    expense_data = @csv_parser.parse_expense_data(file_path)
    logger.info "Storing expense csv file: #{file_path}, count: #{expense_data.count}"
    expense_data.each do |data|
      @keeper.store_expense(data)
    end
    File.delete(file_path) if File.exist?(file_path)
    @keeper.flush_expense
  end  
end
