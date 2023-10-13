# frozen_string_literal: true
require_relative '../lib/database_manager'

class Parser <  Hamster::Parser

  def get_records(response)
    page = Nokogiri::HTML.parse(response.body)
    page.css('.listing')
  end

  def parse_data(elements)
    date_scraping = Date.today

    if elements.empty?
      Hamster.report(to: 'dmitiry.suschinsky', message: '#33 Harris County Tx Delinquent Tax Sale Property - table empty')
    else
      harris_c_tx_tax_runs = HarrisCountyTxDelinquentTaxSalePropertiesRuns.new
      harris_c_tx_tax_runs.last_scrape_date = date_scraping
      DatabaseManager.save_item(harris_c_tx_tax_runs)
      run_id = HarrisCountyTxDelinquentTaxSalePropertiesRuns.last.id

      # карточки
      elements.each do |el|
        address = el.css('.address')[0].text
        city = el.css('.city')[0].text
        state = el.css('.state')[0].text
        zip = el.css('.zip')[0].text

        precinct, sale_nr, type_tax, cause_nr, judgment, tax_years_in_judgement,
          minimum_bid, adjudjed_value, hcad_account_nr, tax_sale_link, desc = ''

        trs = el.css('tr')
        cancelled = el.css('.Cancelled')[0].nil? ? false : true
        trs.each do |tr|
          tds = tr.css('td')

          case tds[0].text.strip
          when 'Precinct:'
            precinct = tds[1].text.strip
          when 'Sale#:'
            sale_nr = tds[1].text.strip
          when 'Type:'
            type_tax = tds[1].text.strip
          when 'Cause#:'
            cause_nr = tds[1].text.strip
          when 'Judgment:'
            judgment = tds[1].text.strip
          when 'Tax Years in Judgement:'
            tax_years_in_judgement = tds[1].text.strip
          when 'Minimum Bid:'
            minimum_bid = tds[1].text.strip
          when 'Adjudged Value:'
            adjudjed_value = tds[1].text.strip
          when 'HCAD Account:'
            hcad_account_nr = 'https://public.hcad.org/records/outsider/hc.asp?acct=' + tds[1].css('form[name]')[0].attribute('name')
          when 'Tax Sale'
            tax_sale_link = tds[1].css('a[href]')[0].attribute('href')
          else
            next
          end
        end

        ps = el.css('p')

        desc = case ps[0].text
               when 'For SaleDescription'
                 ps[1].text
               when 'Description'
                 ps[1].text
               else
                 ''
               end
        # puts '------------------------------------------------------------------------'
        # puts "address: #{address}"
        # puts "city: #{city}"
        # puts "state: #{state}"
        # puts "zip: #{zip}"
        # puts "precinct: #{precinct}"
        # puts "sale_nr: #{sale_nr}"
        # puts "type_tax: #{type_tax}"
        # puts "cause_nr: #{cause_nr}"
        # puts "judgment: #{judgment}"
        # puts "tax_years_in_judgement: #{tax_years_in_judgement}"
        # puts "minimum_bid: #{minimum_bid}"
        # puts "adjudjed_value: #{adjudjed_value}"
        # puts "hcad_account_nr: #{hcad_account_nr}"
        # puts "tax_sale_link: #{tax_sale_link}"
        # puts "description: #{desc}"
        # puts "cancelled: #{cancelled}"
        # puts '------------------------------------------------------------------------'

        hctx_tax_sale = HarrisCountyTxDelinquentTaxSaleProperty.new
        hctx_tax_sale.address = address
        hctx_tax_sale.city = city
        hctx_tax_sale.state = state
        hctx_tax_sale.zip = zip
        hctx_tax_sale.precinct = precinct
        hctx_tax_sale.sale_nr = sale_nr
        hctx_tax_sale.type_tax = type_tax
        hctx_tax_sale.cause_nr = cause_nr
        hctx_tax_sale.judgment = judgment
        hctx_tax_sale.tax_years_in_judgement = tax_years_in_judgement
        hctx_tax_sale.minimum_bid = minimum_bid
        hctx_tax_sale.adjudjed_value = adjudjed_value
        hctx_tax_sale.hcad_account_nr = hcad_account_nr
        hctx_tax_sale.tax_sale_link = tax_sale_link
        hctx_tax_sale.description = desc
        hctx_tax_sale.run_id = run_id
        hctx_tax_sale.cancelled = cancelled

        hctx_tax_sale__exist = HarrisCountyTxDelinquentTaxSaleProperty.where(
          address: hctx_tax_sale.address,
          state: hctx_tax_sale.state,
          city: hctx_tax_sale.city,
          zip: hctx_tax_sale.zip,
          precinct: hctx_tax_sale.precinct,
          type_tax: hctx_tax_sale.type_tax,
          cause_nr: hctx_tax_sale.cause_nr,
          hcad_account_nr: hctx_tax_sale.hcad_account_nr,
          deleted: 0
        ).first

        if hctx_tax_sale__exist.nil?
          hctx_tax_sale.touched_run_id = run_id
          DatabaseManager.save_item(hctx_tax_sale)
        else
          if hctx_tax_sale__exist == hctx_tax_sale
            hctx_tax_sale.run_id = run_id
            hctx_tax_sale.touched_run_id = run_id
            DatabaseManager.save_item(hctx_tax_sale)

            hctx_tax_sale__exist.update(deleted: 1)
          else
            hctx_tax_sale__exist.update(touched_run_id: run_id)
          end
        end
      end
      Hamster.report(to: 'dmitiry.suschinsky', message: '#33 Harris County Tx Delinquent Tax Sale Property - SCRAPE & PARSE --- DONE')
    end
  end

end
