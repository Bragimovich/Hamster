# frozen_string_literal: true

require_relative '../models/san_diego_tax_delinquent_properties_run'
require_relative '../models/san_diego_tax_delinquent_properties_abbreviation'
require_relative '../models/san_diego_tax_delinquent_property'

class Scraper < Hamster::Scraper
  def initialize
    super
  end

  date = Time.now.strftime("%Y-%m").gsub('-', '_')
  FILE_NAME = "san_diego_ca_tax_delinq_prop_for_sale_#{date}"
  ABBR_FILE_NAME = "abbreviation_#{date}"
  RUN_TABLE = SanDiegoTaxDelinquentPropertiesRun
  MAIN_TABLE = SanDiegoTaxDelinquentProperty
  ABBR_TABLE = SanDiegoTaxDelinquentPropertiesAbbreviation

  def get_table
    request = connect_to('https://www2.sdcounty.ca.gov/treastax/taxsale/taxsale.asp?passes=1&ttsa=ID=%22Hidden2%2[%E2%80%A6]ax_rate_area=Select+Tax+Rate+Area&submit=ACTIVE+Properties')
    if request.status == 200
      peon.put(
        file: FILE_NAME,
        content: request.body
      )
    else
      report(to: 'Yunus Ganiyev', message: 'Bad response', use: :both)
    end
  end

  def get_abbr_table
    request = connect_to('https://www2.sdcounty.ca.gov/treastax/taxsale/table.asp#T')
    if request.status == 200
      peon.put(
        file: ABBR_FILE_NAME,
        content: request.body
      )
    else
      report(to: 'Yunus Ganiyev', message: 'Bad response', use: :both)
    end
  end

  def download
    get_table
    get_abbr_table
  rescue => e
    message = <<~MSG
      !!! --- ERROR in #23 San Diego, California Tax Delinquent Properties for sale --- !!!
      #{e.backtrace.map.with_index { |s, i| i.zero? ? "`#{s.gsub(/`/, "'")}`" : "\t#{i}: from `#{s.gsub(/`/, "'")}`" }
         .reverse
         .join("\n")}
    MSG
    Hamster.report(to: 'Yunus Ganiyev', message: message)
  end

  def save_table
    parser = Parser.new
    parser.parse_table(peon.give(file: FILE_NAME))
  end

  def save_abbr_table
    parser = Parser.new
    parser.parse_abbr_table(peon.give(file: ABBR_FILE_NAME))
  end


  def store
    run = RUN_TABLE.order(created_at: :desc).limit(1).to_a.first
    if run.nil?
      fill_table(1)
    elsif run.status == 'done'
      fill_table(run.id)
    else
      fill_table(run.id)
      message = <<~MSG
        !!! --- ERROR in #23 San Diego, California Tax Delinquent Properties for sale --- !!!
        `The previous scraping failed to complete correctly`
      MSG
      Hamster.report(to: 'Yunus Ganiyev', message: message)
      raise
    end
  end

  def fill_table(id)
    RUN_TABLE.create!
    prepare_table(save_table, MAIN_TABLE, id)
    prepare_table(save_abbr_table, ABBR_TABLE, id)
    RUN_TABLE.order(created_at: :desc).limit(1).to_a.first.update(status: 'done')
  end

  def prepare_table(data, table, run_id)
    if run_id == 1
      data.each { |h| h[:run_id] = run_id }
          .each { |h| h[:touched_run_id] = run_id }
          .each { |call| table.store(table.flail { |k| [k, call[k]] }) }
    else
      data.each do |h|
        entity = MAIN_TABLE.where.not(deleted: 1).where(item_nbr: h[:item_nbr]).to_a.first
        if entity.nil?
          h[:run_id] = run_id
          h[:touched_run_id] = run_id
          table.store(table.flail { |k| [k, h[k]] })
        elsif entity[:md5_hash] == h[:md5_hash]
          entity.update(touched_run_id: run_id)
        else
          entity.update(deleted: 1)
          h[:run_id] = run_id
          h[:touched_run_id] = run_id
          table.store(table.flail { |k| [k, h[k]] })
        end
      end
    end
  end
end
