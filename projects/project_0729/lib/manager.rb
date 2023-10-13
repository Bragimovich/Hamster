require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @parser   = Parser.new
    @keeper   = Keeper.new
  end

  def download
    scraper = Scraper.new
    main_page = scraper.get_xls
    save_file(main_page, "source", "#{keeper.run_id}")
    main_page = parser.parse_page(main_page.body)
    links = parser.get_html_data(main_page)
    links.each do |link|
      excel_file = scraper.get_xlsx_file(link)
      save_xlsx(excel_file.body, link.split("-").last.split(".").first)
    end
  end

  def store
    main_page = peon.give(file: "source", subfolder: "#{keeper.run_id}")
    main_page = parser.parse_page(main_page)
    links = parser.get_html_data(main_page)
    links.each do |link|
      file_name = link.split("-").last.split(".").first
      path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.xlsx"
      payroll_data, employee_salaries_data = parser.excel_data(path, link, keeper.run_id)
      keeper.save_record(payroll_data, "EmployeePayroll")
      keeper.save_record(employee_salaries_data, "EmployeeSalaries")
    end
    keeper.finish
  end

  private
  attr_accessor :parser, :keeper

  def save_file(html, file_name, subfolder)
    peon.put content: html.body, file: file_name, subfolder: subfolder
  end

  def save_xlsx(content, file_name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{file_name}.xlsx"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end  
end
