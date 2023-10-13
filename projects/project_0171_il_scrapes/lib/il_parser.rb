# frozen_string_literal: true


class Parser < Hamster::Scraper

  def initialize
    super
    # run_id_class = RunId.new()
    # @run_id = run_id_class.run_id
    # gathering(update)
    #
    # deleted_for_not_equal_run_id(@run_id)
    # run_id_class.finish
  end


  def parse_html_page(html)
    doc = Nokogiri::HTML(html)

    body = doc.css('.ms-WPBody')
    xls_monthes = {}

    body.css('.link-item').each do |link|
      name_month = link.content.split('Disbursements for ')[-1].split(' ').join('_')
      xls_monthes[name_month] = link.css('a')[0]['href']
    end

    xls_monthes
  end





end

def parse_xlsx_file(filename)
  #workbook = Roo::Spreadsheet.open(filename)
  case filename.split('.')[-1]
  when 'xlsx'
    workbook = Roo::Excelx.new(filename)
  when 'xls'
    Roo::Excel.new(filename)
  end

  worksheet_name = workbook.sheets[0]

  num_rows = 0

  worksheet = workbook.sheet(worksheet_name)

  voucher_date = nil
  collection_date = nil
  all_data = {by_location: [], tax_type_totals: []}
  collecting_rows = []

  local_government_name = :local_government

  worksheet.each_row_streaming do |row|
    row_cells = row.map { |cell| cell.value }
    if voucher_date.nil? and row_cells[0].match('VOUCHER DATE:')
      voucher_date = row_cells[0].split(':')[-1].strip
      voucher_date = Date.strptime(voucher_date, '%m/%d/%Y')
      next
    elsif !voucher_date.nil? and collection_date.nil?
      collection_date = Date.parse(row_cells[0])
      next
    elsif row_cells[0].strip=='TOTALS BY TAX TYPE'
      all_data[:by_location] = collecting_rows
      collecting_rows = []
      local_government_name = :tax_type
      next
    elsif row_cells[0].strip == 'TOTAL'
      if !all_data[:by_location].empty?
        collecting_rows.push({
                               voucher_date: voucher_date,
                               collection_date: collection_date,
                               local_government_name => row_cells[0],
                               tax: row_cells[1],
                               vendor: row_cells[2],
                               warrant: row_cells[3],
                               interest_income: row_cells[4],
                               admin_fee: row_cells[5],
                             })
        break
      end
    elsif row_cells[2].nil? or row_cells[0].strip=='Local Goverments'
      next
    end

    collecting_rows.push({
                           voucher_date: voucher_date,
                           collection_date: collection_date,
                           local_government_name => row_cells[0],
                           tax: row_cells[1],
                           vendor: row_cells[2],
                           warrant: row_cells[3],
                           interest_income: row_cells[4],
                           admin_fee: row_cells[5],
                         })

    num_rows += 1
  end
  all_data[:tax_type_totals] = collecting_rows

  puts "Read #{num_rows} rows"

  all_data
end

def parse_xls_file(filename)
  workbook = Roo::Excel.new(filename)

  worksheet_name = workbook.sheets[0]

  num_rows = 0

  worksheet = workbook.sheet(worksheet_name)

  voucher_date = nil
  collection_date = nil
  all_data = {by_location: [], tax_type_totals: []}
  collecting_rows = []

  local_government_name = :local_government

  worksheet.each do |row_cells|
    next if row_cells[0].nil?
      #row_cells = row.map { |cell| cell }
    if voucher_date.nil? and row_cells[0].match('VOUCHER DATE:')
      voucher_date = row_cells[0].split(':')[-1].strip
      voucher_date = Date.strptime(voucher_date, '%m/%d/%Y')
      next
    elsif !voucher_date.nil? and collection_date.nil?
      collection_date = Date.parse(row_cells[0])
      next
    elsif row_cells[0].strip=='TOTALS BY TAX TYPE'
      all_data[:by_location] = collecting_rows
      collecting_rows = []
      local_government_name = :tax_type
      next
    elsif row_cells[0].strip == 'TOTAL'
      #p row_cells
      if !all_data[:by_location].empty?
        collecting_rows.push({
                               voucher_date: voucher_date,
                               collection_date: collection_date,
                               local_government_name => row_cells[0],
                               tax: row_cells[1],
                               vendor: row_cells[2],
                               warrant: row_cells[3],
                               interest_income: row_cells[4],
                               admin_fee: row_cells[5],
                             })
        break
      end
    elsif row_cells[1].nil? or row_cells[0].strip=='Local Goverments'
      next
    end

    collecting_rows.push({
                           voucher_date: voucher_date,
                           collection_date: collection_date,
                           local_government_name => row_cells[0],
                           tax: row_cells[1],
                           vendor: row_cells[2],
                           warrant: row_cells[3],
                           interest_income: row_cells[4],
                           admin_fee: row_cells[5],
                         })

    num_rows += 1
  end
  all_data[:tax_type_totals] = collecting_rows

  puts "Read #{num_rows} rows"

  all_data
end