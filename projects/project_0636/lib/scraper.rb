# frozen_string_literal: true

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}

class Scraper < Hamster::Scraper

  ORIGIN            = "https://www.lasc.org/CourtActions/:year"
  DOCKETS_URL       = "https://www.lasc.org/Dockets?p=Docket_Archive"
  OPINION_PDF_DIR   = "opinion_pdf/"
  DOCKET_PDF_DIR    = "docket_pdf/"

  def download_court_actions_to_html
    years = *(2016..Date.today.year)
    FileUtils.mkdir_p "#{storehouse}store/CourtActions"
    years.each do |year|
      file_name = "#{year}.html"
      url = ORIGIN.gsub(':year', year.to_s)
      connect_to(url: url, method: :get_file, filename: storehouse+"store/CourtActions/" + file_name, headers: HEADERS)      
    end
  end

  def get_dockets_page
    connect_to(url: DOCKETS_URL) 
  end

  def get_court_actions_page(year)
    url = ORIGIN.gsub(':year', year.to_s)
    connect_to(url: url)  
  end
  
  def get_page(url)
    connect_to(url: url)
  end
  
  def download_opinion_pdf(pdf_url)
    FileUtils.mkdir_p "#{storehouse}store/#{OPINION_PDF_DIR}"
    file_name = pdf_url.split('/')[-1]
    connect_to(url: pdf_url, method: :get_file, filename: storehouse+"store/#{OPINION_PDF_DIR}" + file_name, headers: HEADERS)
    return storehouse+"store/#{OPINION_PDF_DIR}" + file_name
  end

  def clear_opinion_pdf
    File.delete(*Dir.glob("#{storehouse}/store/#{OPINION_PDF_DIR}/*.pdf"))
  end

  def clear_docket_pdfs
    File.delete(*Dir.glob("#{storehouse}/store/#{DOCKET_PDF_DIR}/*.pdf"))
  end

  def opinion_pdf_list
    pdf_files = Dir[storehouse + "store/#{OPINION_PDF_DIR}*.pdf"].sort
  end

  def download_docket_pdf(pdf_url)
    FileUtils.mkdir_p "#{storehouse}store/#{DOCKET_PDF_DIR}"
    file_name = pdf_url.split('/')[-1]
    connect_to(url: pdf_url, method: :get_file, filename: storehouse+"store/#{DOCKET_PDF_DIR}" + file_name, headers: HEADERS)
  end
  
  def docket_pdf_list
    pdf_files = Dir[storehouse + "store/#{DOCKET_PDF_DIR}*.pdf"].sort
  end

  def clear_docket_pdf(file_path)
    path = file_path.split('store/').first
    tmp_file_path = path + "processing_now.pdf"
    FileUtils.cp(file_path, tmp_file_path)
    Docsplit.extract_text(tmp_file_path, {pdf_opts: '-layout', output: path })
    File.read(tmp_file_path.sub('.pdf', '.txt'))
  end

  def get_origin_text_from_pdf_file(file_path)
    content = ""
    reader = PDF::Reader.new(file_path)
    reader.pages.each do |page|
      page.text
      content += page.text
      content += "\n\n"
    end
    content
  end

  def store_to_csv(source, file_name)
    FileUtils.mkdir_p "#{storehouse}store/csv"
    path = "#{storehouse}store/csv/#{file_name}"
    CSV.open(path, 'a') do |csv|
      source.each do |record|
        csv << record.values
      end
    end
  end

end
