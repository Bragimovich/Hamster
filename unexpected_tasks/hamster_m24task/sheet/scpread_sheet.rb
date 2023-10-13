require "google/apis/sheets_v4"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

#https://docs.google.com/spreadsheets/d/1AtAOz5BWVXzg7QHoUa-4ABiGwwxDuwNlNqU_LAgGHVc/edit?pli=1#gid=585196294
class SpreadSheetLocy

  LIMIT_RESPONSE = 500
  TIMEWAIT = 1
  LIMIT_ROW = 10000

  attr_accessor :config
  def report message
    Hamster.report(to: "Mikhail Golovanov", message: message, use: :telegram)
  end
  def run

    # # Initialize the API
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = @config.name
    @config.get_token
    service.authorization = @config.authorizer

    offset = 0
    tpage = []
    tquery = []
    last_size_query = 2
    last_size_page = 2
    last_size_scope = 2
    litter = ('A'..'Z').map { |l| l }[6]

    date = GoogleConsoleData.select("DATE(MAX(start_date)) AS start_date").where(name: @config.name).first.start_date
    count = GoogleConsoleData.select("count(url) AS count").where(name: @config.name).group(:url).length
    comp_day = (LIMIT_ROW / count).to_i
    date_start = date - comp_day

    begin
      request_body = Google::Apis::SheetsV4::BatchClearValuesRequest.new
      request_body.ranges = ["'Scope'!A2:G", "'Top page'!A2:G", "'Top query'!A2:G"]
      service.batch_clear_values(@config.spreadsheet, request_body)
      sleep TIMEWAIT
    rescue StandardError => err
      report err.to_s
      sleep TIMEWAIT
      retry if err.to_s.match?(/execution expirede/) or err.to_s.match?(/Timeout:/)
      puts err.to_s
    end

    while (res = GoogleConsoleData.where("name = :name AND start_date > :start_date", { name: @config.name, start_date: date_start }).order(id: :desc).limit(LIMIT_RESPONSE).offset(offset)).count > 0
      tpage = []
      tquery = []

      scope = res.map do |item|
        tpage += item.toppage.map do |pg|
          [item.url, pg.url, pg.click_total.to_s, pg.impressions_total.to_s, pg.ctr.to_s, pg.position.to_s, pg.start_date.strftime("%Y-%m-%d")]
        end
        tquery += item.topquery.map do |tq|
          [item.url.to_s, tq.key, tq.click_total.to_s, tq.impressions_total.to_s, tq.ctr.to_s, tq.position.to_s, tq.start_date.strftime("%Y-%m-%d")]
        end
        [item.url, item.discovered_url, item.click_total, item.impressions_total, item.ctr, item.position, item.start_date.strftime("%Y-%m-%d")]
      end

      range_query = "'Top query'!A#{last_size_query}:G#{tquery.size + last_size_query}"
      range_page = "'Top page'!A#{last_size_page}:G#{tpage.size + last_size_page}"
      range_scope = "'Scope'!A#{last_size_scope}:G#{scope.size + last_size_scope}"

      last_size_query = (tquery.size == 0) ? 2 : tquery.size + last_size_query
      last_size_page = (tpage.size == 0) ? 2 : tpage.size + last_size_page
      last_size_scope = (scope.size == 0) ? 2 : scope.size + last_size_scope

      value_range_query = Google::Apis::SheetsV4::ValueRange.new(values: tquery, range: range_query)
      value_range_page = Google::Apis::SheetsV4::ValueRange.new(values: tpage, range: range_page)
      value_range_scope = Google::Apis::SheetsV4::ValueRange.new(values: scope, range: range_scope)

      request = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new
      request.data = [value_range_scope, value_range_page, value_range_query]
      request.value_input_option = "USER_ENTERED"
      begin
        service.batch_update_values(@config.spreadsheet, request)
      rescue StandardError => err
        report err.to_s
        sleep TIMEWAIT
        retry if err.to_s.match?(/execution expirede/) or err.to_s.match?(/Timeout:/)
      end
      offset += LIMIT_RESPONSE
    end
  end
end