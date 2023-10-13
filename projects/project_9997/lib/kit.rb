require 'pdfkit'

class Kit < Hamster::Harvester
  LINKS = [#'http://www.supremecourt.ohio.gov/Clerk/ecms/#/caseinfo/2016/1914',
    # 'https://scweb.gasupreme.org:8088/results_one_record.php?caseNumber=S16G1463',
    #   'https://www.gaappeals.us/docket/results_one_record.php?docr_case_num=A16I0086', +
    #      'http://www.nycourts.gov/reporter/3dseries/2016/2016_01205.htm', -
    #        'https://www.tncourts.gov/PublicCaseHistory/CaseDetails.aspx?id=65623&Number=True', +
    #    'https://courts.michigan.gov/opinions_orders/case_search/Pages/default.aspx?SearchType=1&CaseNumber=146600&CourtType_CaseNumber=1',
    #      'https://courts.michigan.gov/opinions_orders/case_search/Pages/default.aspx?SearchType=1&CaseNumber=327000&CourtType_CaseNumber=2',
    #      'https://efile.dcappeals.gov/public/caseView.do?csIID=65289' +]
    def initialize
      super
    end

  def main
    # kit = PDFKit.new('http://google.com')
    #kit.stylesheets << "/#{storehouse}store"
    #file = kit.to_file("/#{storehouse}store/google_page.pdf")
    i = 4
    LINKS.each do |link|
      page = get_case_page(link)
      #html = peon.put content: page, file: "#{i}"
      File.open("/#{storehouse}store/#{i}.html", 'w') do |name|
        name.puts page
      end
      kit = PDFKit.new(File.new("/#{storehouse}store/#{i}.html"))
      file = kit.to_file("/#{storehouse}store/sample_storehouse_#{i}.pdf")
      #  kit.to_file("/#{storehouse}store/sample_storehouse_#{i}.pdf")
      i += 1
    end
  end

  def get_case_page(link)
    begin
      request = Hamster.connect_to(
        url: link,
        proxy_filter: @proxy_filter,
        method: :get
      )
      raise if request&.headers.nil?

    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      sleep(rand(5..10))
      retry
    end
    request.body
  end
end
