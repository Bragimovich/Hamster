require_relative '../lib/pa_philadelphia_court_parser'

class PaPhiladelphiaCourtScraper < Hamster::Scraper
  URL         = 'https://ujsportal.pacourts.us/CaseSearch'.freeze
  TOKEN_FORMA = 'CfDJ8DANv3MLDtFApaLm045xx_x_-0I_q2RSf6nxVKjYoSmjOJPztSLFjoMcwO8R3CAoOgihoJ3dC33Yt0G9mYG5C69Q1v1yT8sEXBAazvjewKVIaO-V46A-pck_UzDlirFkA1B9WihoQQNBVaS4PJMwXHk'.freeze

  COOKIE = '.AspNetCore.Antiforgery.SBFfOFqeTDE=CfDJ8DANv3MLDtFApaLm045xx_yBfH9A6G-9mXEJEJ-oBp0Z4DYstR1hb0bv1ggXuwVNEwtUr2nTt5HkzTE7cG22b-9RntlJkTFJ5ctt0XMI4BLsYbXeJbJ7lgFfrerWm3QCRkvGFHxKkiXAaT_OvABYQPI; f5avraaaaaaaaaaaaaaaa_session_=PDOCBDFBPIFCBOCPIHOPHJNHNIPLANEMPBKCMDNHMDOFIALDHKIEGLOKLHNAFGPIGEIDAOGPMFOKKFILENDACCGPDPDNIAANEBLBEJIAMGFEGBLBJBPAMOKIFIILOIGB'.freeze
  COUNTY = 'Philadelphia'
  HEADERS = { content_type: 'application/x-www-form-urlencoded', connection: 'keep-alive',
              host: 'ujsportal.pacourts.us', cookie: COOKIE }

  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @count        = 0
    @keeper       = keeper
    @proxies      = get_proxies
  end

  attr_reader :count

  def scrape_new_cases
    end_date   = Date.today - 1
    start_date = end_date - end_date.mday + 1
    12.times do
      form_data = "SearchBy=DateFiled&AdvanceSearch=true&ParticipantSID=&ParticipantSSN=&FiledStartDate=#{start_date}"\
                  "&FiledEndDate=#{end_date}&County=#{COUNTY}&__RequestVerificationToken=#{TOKEN_FORMA}"
      list_page = connect_to(URL, proxy_filter: @proxy_filter, ssl_verify: false, proxy: @proxies,
                             method: :post, req_body: form_data, headers: HEADERS)&.body
      peon.put(file: start_date.to_s, content: list_page, subfolder: "#{keeper.run_id}_pages")
      parser      = PaPhiladelphiaCourtParser.new(html: list_page)
      court_cases = parser.parse_start_info
      court_cases.each { |item| save_info_pdfs(item) unless keeper.case_exist?(item[:case_id]) }
      start_date = start_date.prev_month
      end_date   = start_date.next_month - 1
    end
  end

  def scrape_active_cases
    keeper.get_active_cases.each { |info| save_info_pdfs(info, :active) }
  end

  private

  attr_reader :keeper

  def save_info_pdfs(info, court_case = :new)
    pdf   = get_response_body(info[:source_link])
    pdf_2 = get_response_body(info[:court_summary])
    return save_pdf_storage_db(info, pdf, pdf_2) if court_case == :new

    md5          = MD5Hash.new(columns: %i[case_id, pdf, pdf_2, link_pdf])
    md5_hash_new = md5.generate({ case_id: info[:case_id], pdf: pdf, pdf_2: pdf_2, link_pdf: info[:source_link] })
    md5_hash_db  = keeper.get_pdfs_md5_hash(info[:case_id])
    save_pdf_storage_db(info, pdf, pdf_2) if md5_hash_db != md5_hash_new
  end

  def save_pdf_storage_db(info, pdf, pdf_2)
    md5  = MD5Hash.new(columns: %i[link])
    name = md5.generate({ link: info[:source_link] })
    keeper.save_start_data(info, pdf, pdf_2)
    peon.put(file: name, content: pdf, subfolder: "#{keeper.run_id}_docket_sheet")
    #peon.put(file: name, content: pdf_2, subfolder: "#{keeper.run_id}_court_summary")
    @count += 1
  end

  def get_response_body(url)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(url, proxy_filter: @proxy_filter, ssl_verify: false, proxy: @proxies)&.body
  end

  def get_proxies
    proxies = PaidProxy.all.pluck(:ip, :port, :login, :pwd, :is_socks5).shuffle
    PaidProxy.connection.close
    proxies.map { |p| "#{p.at(4) ? 'socks' : 'https'}://#{p.at(2)}:#{p.at(3)}@#{p.at(0)}:#{p.at(1)}" }
  end
end
