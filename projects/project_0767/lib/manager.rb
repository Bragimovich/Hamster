# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Scraper
  def initialize(options)
    super

    @options = options
    @scraper = Scraper.new
    @parser  = Parser.new

    @keeper = Keeper.new(
      max_buffer_size: @options[:buffer],
      run_model:       'InPublicEmployeeSalariesRun'
    )
  end

  def run
    data_source_url = 'https://www.in.gov/itp/state-employees/employee-salaries'
    curr_page       = 1
    retry_count     = 0

    begin
      total_pages = nil
      @scraper.reset_cookies

      main_url  = 'https://datavizpublic.in.gov/views/ITP_SALARY_SEARCH/ITP_SalarySearch?:embed=y&:showVizHome=no&:host_url=https:%2F%2Fdatavizpublic.in.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:showAppBanner=false&:display_spinner=no&:loadOrderID=0'
      main_resp = @scraper.get_content(main_url, bypass_codes: [401, 403, 404, 500])
      raise 'Failed to get content' if main_resp.nil?

      app_cfg = @parser.parse_app_config(main_resp)
      sess_id = app_cfg['sessionid']

      boot_url  = "https://datavizpublic.in.gov/vizql/w/ITP_SALARY_SEARCH/v/ITP_SalarySearch/bootstrapSession/sessions/#{sess_id}"
      boot_resp = @scraper.post_payload(boot_url, build_boot_session_payload(app_cfg))
      boot_info = @parser.parse_boot_info(boot_resp)

      notif_url = "https://datavizpublic.in.gov/vizql/w/ITP_SALARY_SEARCH/v/ITP_SalarySearch/sessions/#{sess_id}/commands/tabdoc/notify-first-client-render-occurred"
      @scraper.post_payload(notif_url, {})

      if curr_page > 1
        op_url = "https://datavizpublic.in.gov/vizql/w/ITP_SALARY_SEARCH/v/ITP_SalarySearch/sessions/#{sess_id}/commands/tabdoc/set-parameter-value"
        op_pl  = {
          'globalFieldName' => boot_info[:agcy_param],
          'valueString'     => '(All)',
          'useUsLocale'     => 'false'
        }
        op_resp = @scraper.post_payload(op_url, op_pl, content_type: 'multipart/form-data')
        _, tot_pages, _ = @parser.parse_op_result(op_resp, true)
        total_pages = tot_pages if total_pages.nil?
      end

      while true
        op_url = "https://datavizpublic.in.gov/vizql/w/ITP_SALARY_SEARCH/v/ITP_SalarySearch/sessions/#{sess_id}/commands/tabdoc/set-parameter-value"
        op_pl  = {
          'globalFieldName' => boot_info[curr_page == 1 ? :agcy_param : :page_param],
          'valueString'     => curr_page == 1 ? '(All)' : curr_page,
          'useUsLocale'     => 'false'
        }
        op_resp = @scraper.post_payload(op_url, op_pl, content_type: 'multipart/form-data')
        curr_page, tot_pages, data = @parser.parse_op_result(op_resp, total_pages.nil?)
        total_pages = tot_pages if total_pages.nil?

        data.each do |entry|
          entry[:data_source_url] = data_source_url
          @keeper.save_data('InPublicEmployeeSalary', entry)
        end

        break if curr_page == total_pages
        curr_page += 1
        retry_count = 0
      end
    rescue => e
      cause_exc = e.cause || e
      raise e if cause_exc.is_a?(::Mysql2::Error) || cause_exc.is_a?(::ActiveRecord::ActiveRecordError)
      raise e if retry_count >= 10

      retry_count += 1
      retry
    end

    @keeper.flush
    @keeper.mark_deleted
    @keeper.finish
  rescue Exception => e
    cause_exc = e.cause || e
    unless cause_exc.is_a?(::Mysql2::Error) || cause_exc.is_a?(::ActiveRecord::ActiveRecordError)
      @keeper.flush rescue nil
    end
    raise e
  end

  private

  def build_boot_session_payload(cfg)
    {
      'worksheetPortSize'                 => JSON.generate({ w: 1184, h: 730 }),
      'dashboardPortSize'                 => JSON.generate({ w: 1184, h: 730 }),
      'clientDimension'                   => JSON.generate({ w: 946, h: 969 }),
      'renderMapsClientSide'              => 'true',
      'isBrowserRendering'                => 'true',
      'browserRenderingThreshold'         => '100',
      'formatDataValueLocally'            => 'false',
      'clientNum'                         => '',
      'navType'                           => 'Reload',
      'navSrc'                            => 'Top',
      'devicePixelRatio'                  => '1',
      'clientRenderPixelLimit'            => '16000000',
      'allowAutogenWorksheetPhoneLayouts' => 'true',
      'sheet_id'                          => 'ITP_SalarySearch',
      'showParams'                        => cfg['showParams'],
      'stickySessionKey'                  => cfg['stickySessionKey'],
      'filterTileSize'                    => '200',
      'locale'                            => 'en_US',
      'language'                          => 'en',
      'verboseMode'                       => 'false',
      ':session_feature_flags'            => '{}',
      'keychain_version'                  => cfg['keychain_version'].to_s
    }
  end
end
