require_relative '../lib/pa_sc_case_parser'

class PaScCaseScraper < Hamster::Scraper
  URL         = 'https://ujsportal.pacourts.us/CaseSearch'.freeze
  TOKEN_FORMA = 'CfDJ8DANv3MLDtFApaLm045xx_y0ecizE1YjAnKG2FH8yLj-PsAneTv6EctOmnf_jC9agOzfZ5PM4tDcMfegy0-Ax7YVVZrsc8_'\
                'JdpKGvIJ3NleRfooV4diqjzIxMccTp4hpW1ZE94FjV3NvPrL4pMSCU6E'.freeze

  COOKIE = '.AspNetCore.Antiforgery.SBFfOFqeTDE=CfDJ8DANv3MLDtFApaLm045xx_xnIoLa0aniVP7DXExDqxtDa84bK9Zv-gc41WRc5b'\
           'Rs3xIrdSFnBKA7zNzbD0curR6wTrxPRSdFwTae-7ulkx4i9GAzHbff9Bxy_LpKTvhPUowKNgnY8wIHl5plNApW8lA; '\
           'f5avraaaaaaaaaaaaaaaa_session_=MIINKFBIEHCEOIICIMEPGGJEIPGIOPPAPDIHGHLNPDNKBKGAGLNKENCDKJDDMD'\
           'PMLHKDCHABIGJANHFKPGMAJDOEOKNPOPEOACBKMJPJPCLCCPKGIEFNFFOBMJKIPBHO'.freeze

  def initialize(keeper)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @user_agents  = UserAgent.where(device_type: 'Desktop User Agents').pluck(:user_agent)
    UserAgent.connection.close
    @count  = 0
    @keeper = keeper
  end

  attr_reader :count

  def scrape_new_cases
    end_date   = Date.today - 1
    start_date = end_date - end_date.mday + 1

    12.times do
      form_data = "SearchBy=AppellateCourtName&FiledStartDate=#{start_date}&FiledEndDate=#{end_date}"\
                  "&AppellateCourtName=Supreme&__RequestVerificationToken=#{TOKEN_FORMA}"

      headers   = { content_type: 'application/x-www-form-urlencoded', connection: 'keep-alive',
                    host: 'ujsportal.pacourts.us', cookie: COOKIE, user_agent: @user_agents.sample }

      list_page = connect_to(URL, proxy_filter: @proxy_filter, ssl_verify: false,
                                  method: :post, req_body: form_data, headers: headers)
      peon.put(file: start_date.to_s, content: list_page, subfolder: "#{keeper.run_id}_pages")
      parser        = PaScCaseParser.new(html: list_page)
      court_cases   = parser.parse_start_info
      case_for_save = keeper.not_saved_cases(court_cases)
      case_for_save.each { |data| save_info_pdf(data) }

      start_date = start_date.prev_month
      end_date   = start_date.next_month - 1
    end
  end

  def scrape_active_cases
    keeper.get_active_cases.each { |i| save_info_pdf(i) }
  end

  private

  attr_reader :keeper

  def save_info_pdf(info)
    pdf  = get_response(info[:source_link])
    md5  = MD5Hash.new(columns: %i[link])
    name = md5.generate({ link: info[:source_link] })
    keeper.save_start_data(info, pdf)
    peon.put(file: name, content: pdf, subfolder: "#{keeper.run_id}_pdfs")
    @count += 1
  end

  def get_response(*arguments)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    connect_to(arguments[0], proxy_filter: @proxy_filter, ssl_verify: false, headers: { user_agent: @user_agents.sample })
  end

  def connect_to(*arguments)
    10.times do
      response = super(*arguments)
      return response.body if [200, 304].include?(response&.status)
    end
  end
end
