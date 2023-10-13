class Scraper < Hamster::Scraper

  def fetch_main_page
    connect_to("https://www.benefits.va.gov/HOMELOANS/lender_state_volume.asp")
  end

  def file_downloading(link, run_id, file)
    FileUtils.mkdir_p("#{storehouse}store/#{run_id}")
    Hamster.connect_to(link, method: :get_file, filename: "#{storehouse}store/#{run_id}/#{file}")
  end
end
