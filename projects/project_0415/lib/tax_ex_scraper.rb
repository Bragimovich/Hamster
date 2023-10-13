# frozen_string_literal: true

class Scraper < Hamster::Scraper

  @run_id = 1

  def initialize(update=0)
    super
    run_id_class = RunId.new()
    @run_id = run_id_class.run_id

    read_data(update)

    deleted_for_not_equal_run_id(@run_id) if update==1
    run_id_class.finish

  end

  def check_update(update)
    url = "https://www.irs.gov/ru/charities-non-profits/tax-exempt-organization-search-bulk-data-downloads"
    html = open(url)
    doc = Nokogiri::HTML(html)
    last_update = doc.xpath(
      '//div[@class="field field--name-body field--type-text-with-summary field--label-hidden field--item"]/p[9]/strong'
    )
    m, d, y = last_update.text[1..].sub(",", " ").strip().split()
    date = "#{y}-#{m}-#{d}"

    if TaxExempt.exists?(last_date: date)
      return false, date
    else
      return true, date
    end

  end

  def read_data(update)
    need_update, date = check_update(update)
    if need_update
      update_data(date, update, @run_id)
    end
  end

end