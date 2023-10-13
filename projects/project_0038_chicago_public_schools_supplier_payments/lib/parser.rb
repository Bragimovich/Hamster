# frozen_string_literal: true
require_relative '../lib/database_manager'

class Parser < Hamster::Parser
  def initialize
    y = Date.parse(Time.now.to_s)

    @run_id = nil
    @scraping_date = Time.now
    @scrape_dev_name = 'Dmitry Suschinsky'
    @date_scraping = Date.today
    @scrape_status = 'active'
    @scrape_frequency = 'year'
    @scrape_last_date = Time.now
    @scrape_next_date = (y.year + 1).to_s
  end

  def get_records(response)
    JSON.parse(response.body)
  end

  def parse_data(elements)
    begin
      if elements.empty?
        Hamster.report(to: 'dmitiry.suschinsky', message: '#38 - table empty')
      else

        mark_as_started
        # карточки
        count = elements.size
        elements.each do |hash|
          chicago_payments = ChicagoPublicSchoolsSuppliersPayments.new

          chicago_payments.supplier_payment_id = hash['SupplierPaymentID']
          chicago_payments.oracle_vendor_id = hash['OracleVendorID']
          chicago_payments.fiscal_year = hash['FiscalYear']
          chicago_payments.supplier_id = hash['SupplierID']
          chicago_payments.name = hash['Name']
          chicago_payments.full_address = hash['FullAddress']
          chicago_payments.city = hash['City']
          chicago_payments.state = hash['State']
          chicago_payments.zip_code = hash['ZipCode']
          chicago_payments.payment_amount = hash['PaymentAmount']
          chicago_payments.created_date = Date.parse(hash['CreatedDate']).strftime('%m/%d/%Y') if hash['CreatedDate'] && hash['CreatedDate'] != 'N/A'
          chicago_payments.created_by = hash['CreatedBy']
          chicago_payments.updated_date = Date.parse(hash['UpdatedDate']).strftime('%m/%d/%Y') if hash['UpdatedDate'] && hash['UpdatedDate'] != 'N/A'
          chicago_payments.updated_by = hash['UpdatedBy']

          chicago_payments.run_id = @run_id
          chicago_payments.last_scrape_date = @scrape_last_date
          chicago_payments.next_scrape_date = @scrape_next_date
          chicago_payments.expected_scrape_frequency = @scrape_frequency
          chicago_payments.scrape_status = @scrape_status

          DatabaseManager.save_item(chicago_payments)
        end
      end
      Hamster.report(to: 'dmitiry.suschinsky', message: '#38 - SCRAPE & PARSE --- DONE')
    rescue SystemExit, Interrupt, StandardError, ActiveRecord::ActiveRecordError => e
      Hamster.report(to: 'Dmitiry Suschinsky', message: "SCRAPE & PARSE ERROR #38\n#{e}")
    end
  end

  def mark_as_started
    last_row = ChicagoPublicSchoolsSuppliersPaymentsRuns.last
    if last_row && last_row.status == 'parse started'
      @run_id = last_row.id
    else
      ChicagoPublicSchoolsSuppliersPaymentsRuns.create
      @run_id = ChicagoPublicSchoolsSuppliersPaymentsRuns.last.id
      ChicagoPublicSchoolsSuppliersPaymentsRuns.find(@run_id).update(status: 'parse started')
      ChicagoPublicSchoolsSuppliersPaymentsRuns.find(@run_id - 1).update(status: 'done') if @run_id > 1
    end
  end

end
