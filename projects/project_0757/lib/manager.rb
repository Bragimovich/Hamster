require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize(**options)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new

    @peon = Peon.new(storehouse)

    @md5_cash_maker = {
      :fdic_bank_failures => MD5Hash.new(columns:%i[name cert fin city state effective_date insurance_fund resolution estimated_loss transaction_type charter_class total_deposits total_assets data_source_url]),
    }

    @url = "https://banks.data.fdic.gov/explore/failures?aggReport=detail&displayFields=NAME%2CCERT%2CFIN%2CCITYST%2CFAILDATE%2CSAVR%2CRESTYPE%2CCOST%2CRESTYPE1%2CCHCLASS1%2CQBFDEP%2CQBFASSET&endFailYear=2023&sortField=FAILDATE&sortOrder=desc&startFailYear=2012"

    download if options[:download]
    store if options[:store]

  end


  def download
    # Download html_page
    html_page = @scraper.download_main_html_page(@url)
    @peon.put(content: html_page, file: "FDIC_Bank_Failures_Assistance_Data_page_#{Date.today.strftime("%m-%d-%Y")}")

    # Download CSV file
    html_page = @peon.give(file: "FDIC_Bank_Failures_Assistance_Data_page_#{Date.today.strftime("%m-%d-%Y")}")
    url_of_cvs_file = @parser.parse_link_for_download_cvs_data(html_page)
    @scraper.download_cvs_file(URI(url_of_cvs_file))
  end

  def store

    data = @parser.parse_cvs_data("#{storehouse}store/bank-data_#{Date.today.strftime("%m-%d-%Y")}.csv")

    data.each do |hash|
      hash[:data_source_url] = @url
      hash[:md5_hash] = @md5_cash_maker[:fdic_bank_failures].generate(hash)
      if @keeper.existed_data(hash[:md5_hash]).nil? then @keeper.save_data_to_fdic_bank_failures(hash) end
    end

    @keeper.finish
  end


end
