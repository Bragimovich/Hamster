# frozen_string_literal: true

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}

class Scraper < Hamster::Scraper

  ORIGIN = 'https://www.nebraska.gov/apps-courts-epub/public/:court_type'
  ROOT_LINK_PREFIX = 'https://www.nebraska.gov'

  def initialize
    super
    @peon = Peon.new(storehouse)
    @s3 = AwsS3.new(bucket_key = :us_court)
    @pdf_path = nil
  end

  def store_to_csv(source, file_name)
    path = "#{storehouse}store/csv/#{file_name}"
    CSV.open(path, 'a') do |csv|
      source.each do |record|
        csv << record.values
      end
    end
  end
  
  def get_source(source_url)
    @result = connect_to(source_url)
    @result.body
  end

  def get_outer_page(court_type)
    url = ORIGIN.gsub(':court_type', court_type)
    get_source(url)
  end

  def get_content_from_file(file_name)
    content = File.read(storehouse+"store/" + file_name)
  end

  def get_content_from_pdf(pdf_file, max_page=10)
    reader = PDF::Reader.new(storehouse+"store/pdf/" + pdf_file)
    content = ""
    
    header_lines = []
    if reader.pages.length > 1
      reader.pages[1].text.each_line do |line|
        line = line.strip
        next if line == ''
        next unless line.scan(/- \d+ -/).empty?
        if reader.pages.length > 2
          unless reader.pages[2].text.index(line).nil?
            header_lines.push(line)
          else
            break
          end
        end
      end
    end
    reader.pages.each_with_index do |page, index|
      clean_page_content = page.text.gsub(/- \d+ -/, "\n")
      header_lines.each do |header_line|
        header_line = "    #{header_line}\n"
        clean_page_content = "\n" + clean_page_content.gsub(/#{header_line}/, "\n")
      end
      
      content = content + clean_page_content

      stop_words = ['JJ.', '    introduction', '    nature of case', '    background', '  i.']
      stop_words.each do |wd|
        to_index = clean_page_content.downcase.index(wd)
        return content unless to_index.nil?
      end
      break if index >= max_page
    end
    content
  end

  # download html of opinion pdf lists 
  def download_html(url, filename)
    connect_to(url: url, method: :get_file, filename: storehouse+"store/" + filename, headers: HEADERS)
  end

  def get_file_content(filename)
    content = File.read(storehouse+"store/" + filename)
  end

  def save_to_aws(**params)
    pdf_name = params[:url].scan(/docId=(.*)/)[0][0] + ".pdf"
    file_name = Digest::MD5.hexdigest(pdf_name)
    
    pdf_path = get_pdf_path(params[:court_id])
    # puts "#{pdf_path}/#{pdf_name}"
    body = params[:content] || File.read("#{pdf_path}/#{pdf_name}")
    key = "us_courts_expansion/#{params[:court_id]}/#{params[:case_id]}/#{file_name}" + params[:extension]
    @s3.find_files_in_s3(key).empty? ? @s3.put_file(body, key, metadata={url: params[:url]}) : "https://court-cases-activities.s3.amazonaws.com/#{key}"
  end

  def download(links)
    links.each do |html_link, pdf_link|
      file_name = pdf_link.split('=')[2].sub('&', '.')
      begin
        get_file(pdf_link, file_name)
        @peon.put(content: get_source(html_link).body, file: file_name, subfolder: 'gz')
      rescue => error
        # p error
      end
    end
  end
  
  def pdf_list
    pdf_files = Dir[storehouse + "store/*.pdf"].sort
    pdf_files.delete_if {|el| el.include?(TEST_CASE)}
  end
  
  def save_file(html, file_name, subfolder)
    @peon.put content: html, file: file_name, subfolder: subfolder
  end

  def load_file(file_name, subfolder)
    @peon.give(subfolder: subfolder, file: file_name)
  end

  def create_subfolder(subfolder, full_path: false)
    path = "#{storehouse}store/#{subfolder}"
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
    full_path ? path : subfolder
  end
  
  def get_pdf_path(court_id)
    court_type = Manager::COURTS.select{|k, v| k if v==court_id}.keys[0].to_s
    path = "#{storehouse}store/pdf/#{court_type}"
  end

  def download_pdf(court_type, pdf_url)
    pdf_name = pdf_url.scan(/docId=(.*)/)[0][0] + ".pdf"
    # puts "Downloading PDF from #{pdf_url}"
    full_path = create_subfolder("pdf/#{court_type}", full_path: true)
    connect_to(url: pdf_url, method: :get_file, filename: storehouse+"store/pdf/#{court_type}/" + pdf_name, headers: HEADERS)
    full_path + "/" + pdf_name
  end

  def clear_pdf(court_type, pdf_url)
    pdf_name = pdf_url.scan(/docId=(.*)/)[0][0] + ".pdf"
    File.delete(*Dir.glob("#{storehouse}store/pdf/#{court_type}/#{pdf_name}"))
  end

  def get_text_from_pdf(pdf_full_path, max_page=10)

    reader = PDF::Reader.new(pdf_full_path)
    content = ""
    
    header_lines = []
    if reader.pages.length > 1
      reader.pages[1].text.each_line do |line|
        line = line.strip
        next if line == ''
        next unless line.scan(/- \d+ -/).empty?
        if reader.pages.length > 2
          unless reader.pages[2].text.index(line).nil?
            header_lines.push(line)
          else
            break
          end
        end
      end
    end
    reader.pages.each_with_index do |page, index|
      clean_page_content = page.text.gsub(/- \d+ -/, "\n")
      header_lines.each do |header_line|
        header_line = "    #{header_line}\n"
        clean_page_content = "\n" + clean_page_content.gsub(/#{header_line}/, "\n")
      end
      
      content = content + clean_page_content

      stop_words = ['JJ.', '    introduction', '    nature of case', '    background', '  i.']
      stop_words.each do |wd|
        to_index = clean_page_content.downcase.index(wd)
        return content unless to_index.nil?
      end
      break if index >= max_page
    end
    content
  end
end
