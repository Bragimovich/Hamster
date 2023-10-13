# frozen_string_literal: true

require_relative 'connector'
require_relative 'parser'

class Scraper < Hamster::Scraper
  BASE_PATH       = 'https://casesearch.courts.state.md.us'
  START_PAGE      = BASE_PATH + '/casesearch/processDisclaimer.jis'
  DC_SEARCH_PAGE  = BASE_PATH + '/casesearch/inquirySearchParam.jis'
  DC_POST_PATH    = BASE_PATH + '/casesearch/inquirySearch.jis'
  AC_SEARCH_PAGE  = BASE_PATH + '/casesearch/inquiryByCompany.jis'
  AC_POST_PATH    = BASE_PATH + '/casesearch/appellatePersonInquirySearch.jis'
  COURT_TYPE_AC   = 'ac'
  COURT_TYPE_DC   = 'dc'

  def initialize(first_name, last_name, court_type, manager)
    super
    @first_name  = "#{first_name}%"
    @last_name   = "#{last_name}%"
    @court_type  = court_type
    @connector   = MarylandConnector.new(START_PAGE, manager)
    @parser      = Parser.new
    @search_url  = court_type == COURT_TYPE_AC ? AC_SEARCH_PAGE : DC_SEARCH_PAGE
    @post_url    = court_type == COURT_TYPE_AC ? AC_POST_PATH : DC_POST_PATH
  end

  def scrape(search_form_data_list)
    search_form_data_list.each do |form_data|
      file_name =
        if @court_type == COURT_TYPE_AC
          [form_data['lastName'], form_data['firstName'], form_data['partyType']].join('-')
        else
          [form_data['lastName'], form_data['firstName'], form_data['countyName'], form_data['courtSystem'], form_data['site']].join('-')
        end
      file_path   = "#{store_file_path(@court_type)}/#{file_name}.dat"
      member_list = []

      next if File.exists?(file_path)

      search_page = @connector.do_connect(@search_url)
      searchtype = @parser.search_type(search_page.body)
      
      # Firstly, tried to get search results without the date range.
      # Next, if the items are less than 500, didn't use the date range.
      # If the items are more than 500, have to use the date range.
      form_data['searchtype'] = searchtype
      search_page = @connector.do_connect(@post_url, method: :post, data: form_data)
      @prev_items_count, items, page_links = @parser.parse_first_page(search_page.body)
      p '======================parse_first_page====================', @prev_items_count, items
      if @prev_items_count < 500
        member_list << items # first page items
        page_links.each do |page_link|
          search_page = @connector.do_connect("#{BASE_PATH}#{page_link}")
          member_list.concat(@parser.parse_items(search_page.body))
        end
      else
        filling_year = Date.today.year
        # Redirecting to the search page again to use the date range filter.
        search_page = @connector.do_connect(@search_url)
        searchtype = @parser.search_type(search_page.body)
        while filling_year >= 1965 do
          retry_count = 0
          to_date = Date.today.change(year: filling_year)
          if @prev_items_count&.zero?
            filling_year = 1960
          elsif @prev_items_count && (@prev_items_count < 50)
            filling_year -= 5
          else
            filling_year -= 1
          end
          from_date = Date.today.change(year: filling_year)

          begin
            form_data['searchtype'] = searchtype
            form_data['filingStart'] = from_date.strftime('%-m/%d/%Y')
            form_data['filingEnd'] = to_date.strftime('%-m/%d/%Y')
            search_page = @connector.do_connect(@post_url, method: :post, data: form_data)
            @prev_items_count, items, page_links = @parser.parse_first_page(search_page.body)
            p '======================parse_first_page====================', @prev_items_count, items
            member_list << items # first page items
            page_links.each do |page_link|
              search_page = @connector.do_connect("#{BASE_PATH}#{page_link}")
              member_list.concat(@parser.parse_items(search_page.body))
            end
            # Redirecting to the search page again for getting the searchkey.
            search_page = @connector.do_connect(@search_url)
            searchtype = @parser.search_type(search_page.body)
          rescue StandardError => e
            retry_count += 1
      
            raise e if retry_count > 3
      
            main_page = @connector.do_connect(@search_url)
            searchtype = @parser.search_type(main_page.body)
            retry
          end
        end
      end

      File.open(file_path, 'w+') do |f|
        f.puts(member_list.uniq)
      end
    end
  end

  def store_file_path(court_type)
    file_path = "#{storehouse}store/#{court_type}"
    FileUtils.mkdir_p(file_path)
    file_path
  end

  def proxy
    @connector.proxy
  end
end
