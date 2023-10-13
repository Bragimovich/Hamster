require_relative '../models/aaa_gas_prices'
require_relative '../models/aaa_gas_prices_metro_areas'
require_relative '../models/aaa_gas_prices_daily_runs'

class Keeper
  def initialize
    @count  = 0
    @run_id = run.run_id
  end

  attr_reader :run_id, :count

  def status=(new_status)
    run.status = new_status
  end

  def status
    run.status
  end

  def finish
    run.finish
  end

  def get_last_date
    AaaGasPrices.maximum :report_date
  end

  def save_metro_area(data)
    data.each do |i|
      cells = i[:cells]
      aaa_gas_price = AaaGasPricesMetro.new
      aaa_gas_price.report_date = i[:report_date]
      aaa_gas_price.state       = i[:state]
      aaa_gas_price.metro_area  = i[:metro_area]
      prepare_model(aaa_gas_price, cells)
      aaa_gas_price.save
    end
  end

  def save_prices(data)
    cells = data[:cells]
    aaa_gas_price = AaaGasPrices.new
    aaa_gas_price.report_date = data[:report_date]
    aaa_gas_price.state       = data[:state]
    prepare_model(aaa_gas_price, cells)
    aaa_gas_price.save
    @count += 1
  end

  def prepare_model(aaa_gas_price, cells)
    aaa_gas_price.current_regular_price   = cells[0][0]
    aaa_gas_price.current_mid_grade_price = cells[0][1]
    aaa_gas_price.current_premium_price   = cells[0][2]
    aaa_gas_price.current_diesel_price    = cells[0][3]
    aaa_gas_price.current_e85_price       = cells[0][4]

    aaa_gas_price.yesterday_regular_price   = cells[1][0]
    aaa_gas_price.yesterday_mid_grade_price = cells[1][1]
    aaa_gas_price.yesterday_premium_price   = cells[1][2]
    aaa_gas_price.yesterday_diesel_price    = cells[1][3]
    aaa_gas_price.yesterday_e85_price       = cells[1][4]

    aaa_gas_price.week_ago_regular_price   = cells[2][0]
    aaa_gas_price.week_ago_mid_grade_price = cells[2][1]
    aaa_gas_price.week_ago_premium_price   = cells[2][2]
    aaa_gas_price.week_ago_diesel_price    = cells[2][3]
    aaa_gas_price.week_ago_e85_price       = cells[2][4]

    aaa_gas_price.month_ago_regular_price   = cells[3][0]
    aaa_gas_price.month_ago_mid_grade_price = cells[3][1]
    aaa_gas_price.month_ago_premium_price   = cells[3][2]
    aaa_gas_price.month_ago_diesel_price    = cells[3][3]
    aaa_gas_price.month_ago_e85_price       = cells[3][4]

    aaa_gas_price.year_ago_regular_price   = cells[4][0]
    aaa_gas_price.year_ago_mid_grade_price = cells[4][1]
    aaa_gas_price.year_ago_premium_price   = cells[4][2]
    aaa_gas_price.year_ago_diesel_price    = cells[4][3]
    aaa_gas_price.year_ago_e85_price       = cells[4][4]

    aaa_gas_price.run_id = run_id
  end

  private

  def run
    RunId.new(AaaGasPricesDailyRuns)
  end
end
