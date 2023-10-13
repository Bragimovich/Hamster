require_relative '../models/MidlandCountyCovidCasesDaily'

class Store < Hamster::Parser
  MONTH_NAME = I18n.t("date.month_names")
  WEEKDAY_NAME = I18n.t("date.abbr_day_names")

  def initialize(run_id)
    super
    @run_id = run_id
  end

  def hash_item(itm)
    str = itm.map {|i| i}.join
    Digest::MD5.hexdigest(str)
  end

  def store(item)



    item[:data].each_with_index do |i, j|

      tmp_date = i
      md5 = hash_item(tmp_date)

      if (rec=MidlandCountyCovidCasesDaily.find_by(md5_hash: md5, deleted: 0)).nil?
        rec = MidlandCountyCovidCasesDaily.new
        rec.run_id = @run_id.to_s
        rec.year = tmp_date[:year]
        rec.month = tmp_date[:month]
        rec.date = tmp_date[:day]
        rec.day_of_week = tmp_date[:day_names]
        rec.date_at = tmp_date[:date]
        rec.covid_cases_count = tmp_date[:value]
        rec.touched_run_id = @run_id.to_s
        rec.md5_hash = md5
        rec.data_source_url = "https://www.midlandtexas.gov/982/Midland-County-DailyWeekly-COVID-19-Case"
        rec.save
      else
        rec.touched_run_id = @run_id.to_s
        rec.save
      end
    end

  end

  def deleted
    MidlandCountyCovidCasesDaily.where("touched_run_id < ?", @run_id).update(deleted: 1)
  end

  def parser(arr)
    arr.each { |item| store(item) }
    deleted
  end
end
