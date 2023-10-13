# frozen_string_literal: true
START_YEAR = 2015
# START_YEAR = 2023

class Helper < Hamster::Scraper
  def all_cases(court_id)
    parse = Parser.new(court_id)
    cobble = Dasher.new(:using=>:cobble)

    @court = COURTS[court_id]

    parsing_intervals.map do |interval|
      parse.index_page(cobble.get(url(interval)))
      .map {|el| el.merge({court_id: court_id})}
    end.flatten
  end

  def parsing_intervals
    today = Date.today
    number_of_monthes = (today.year - START_YEAR) * 12 + today.month
    (0..number_of_monthes.pred).map do |n|
      { year: today.prev_month(n).year,
        month: today.prev_month(n).month}
    end
  end

  def url(interval)
    begin_str = "#{interval[:month]}/01/#{interval[:year]}"
    begin_date = Date.strptime(begin_str, "%m/%d/%Y")
    end_date = begin_date.next_month - 1
    end_str = begin_str.sub('/01/', "/#{end_date.day}/")
    "https://caseinfo.arcourts.gov/cconnect/PROD/public/ck_public_qry_doct.cp_dktrpt_new_case_report?backto=C&case_id=&begin_date=#{begin_str}&end_date=#{end_str}&county_code=ALL&cort_code=ALL&locn_code=#{@court}&case_type=ALL&docket_code="
  end
end
