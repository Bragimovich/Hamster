require 'nokogiri'
require 'uri'
require_relative 'connector'
require_relative 'parser'

class Scraper < Hamster::Scraper
  START_PAGE      = 'https://hsba.org/HSBA_2020/For_the_Public/Find_a_Lawyer/HSBA_2020/Public/Find_a_Lawyer.aspx'
  MEMBERSHIP_PAGE = 'https://hsba.org/HSBA/Membership_Directory.aspx'

  def initialize(first_name = nil, last_name = nil)
    super
    @first_name = first_name || ''
    @last_name = last_name || ''
    @parser = Parser.new
    @connector = HsbaConnector.new(Scraper::START_PAGE)
  end

  def scrape(&block)
    raise 'Block must be given' unless block_given?

    response = @connector.do_connect("#{Scraper::MEMBERSHIP_PAGE}?#{name_filter_query}")
    @form_fields, @server_id, @lister_panel_name, @submit_button_name, @fname_box_name, @lname_box_name = @parser.extract_form_fields(response)
    # Fetch the first page
    member_list = extract_data_page
    member_list.each(&block)
    # Loop from page 2 to pagecount
    current_page = 2
    page_count = @page_count || 1
    while current_page <= page_count
      member_list = extract_data_page(current_page)
      current_page += 1
      member_list.each(&block)
    end
  end

  private

  def do_post(url, extra_data = nil, save_cookies: true, use_cookies: true)
    data_fields = @form_fields || {}
    data_fields = data_fields.merge(extra_data || {})

    @connector
      .do_connect(
        url,
        data:         data_fields,
        method:       :post,
        save_cookies: save_cookies,
        use_cookies:  use_cookies
      )
  end

  def extract_data_page(page = 1)
    req_data     = requeset_per(page)
    response     = do_post("#{Scraper::MEMBERSHIP_PAGE}?#{name_filter_query}", req_data)
    resp_data    = @parser.parse_form_response(response.body)
    @page_count  = @parser.set_page_count_from_response(response.body, @page_count)
    @form_fields = @parser.update_form_fields_from_response(resp_data, @form_fields)

    member_list, frag   = @parser.parse_members(resp_data, @lister_panel_name)
    updated_form_fields = @parser.update_form_fields_from_fragment(frag, @form_fields)
    @form_fields        = updated_form_fields[:form_fields]
    @go_page_box_name   = updated_form_fields[:go_page_box_name]
    @go_page_btn_name   = updated_form_fields[:go_page_btn_name]
    @go_page_btn_text   = updated_form_fields[:go_page_btn_text]
    @go_page_state_name = updated_form_fields[:go_page_state_name]
    raise 'Found empty page, try again!' if page < @page_count && member_list.count < 20
    member_list
  end

  def requeset_per(page)
    req_data = { '__ASYNCPOST' => 'true' }
    req_data[@fname_box_name] = @first_name
    req_data[@lname_box_name] = @last_name
    req_data['__EVENTARGUMENT'] = ''

    if page > 1
      if @go_page_box_name.nil? ||
         @go_page_btn_name.nil? ||
         @go_page_state_name.nil?
        return req_data
      end

      req_data[@go_page_box_name] = page.to_s
      req_data[@server_id] = "#{@lister_panel_name}|#{@go_page_btn_name}"
      req_data['__EVENTTARGET'] = ''
      req_data[@go_page_state_name] = <<~DATA.gsub(/\r|\n|\r\n/, ' ').squeeze(' ')
        {"enabled":true,"emptyMessage":"","validationText":"#{page}",
        "valueAsString":"#{page}","minValue":1,"maxValue":#{@page_count},
        "lastSetTextBoxValue":"#{page}"}
      DATA
      req_data[@go_page_btn_name] = @go_page_btn_text
    else
      req_data[@server_id] = "#{@lister_panel_name}|#{@submit_button_name}"
      req_data['__EVENTTARGET'] = @submit_button_name
    end
    req_data
  end

  def name_filter_query
    f_name = CGI.escape(@first_name)
    l_name = CGI.escape(@last_name)
    "FirstName=#{f_name}&LastName=#{l_name}"
  end
end
