# frozen_string_literal: true

require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  def download_csv(source)
    puts ['*'*77, "Download csv from #{source}"]
    file_name = csv_path
    file_name = file_name.sub('USA', 'WORLD') if source.eql?(WORLD_CSV_LINK)
    connect_to(source, method: :get_file, filename: file_name)
    file_name
  end

  def get_source(url)
    connect_to(url: url, headers: HEADERS)
  end

  def csv_path
    prefix = Time.now.to_s.split[0]
    suffix = 'USA-CSV'
    "#{storehouse}store/#{prefix}-#{suffix}.csv"
  end

  def store_csv(csv_lines)
    CSV.open(csv_path, 'w') do |csv|
      csv << csv_lines[0].keys
      csv_lines.each { |line| csv << line.values }
    end
  end

  def download_to_pdf(url)
    time_now = Time.now
    date = Time.at(time_now.to_i / DAY * DAY)
    prefix = date.to_s.split[0]
    suffix = 'USA'
    path = "#{storehouse}store/#{prefix}-#{suffix}.pdf"

    hammer = Hamster::Scraper::Dasher.new(using: :hammer)
    hammer.get(url)
    browser = hammer.connect
    browser.go_to(url)
    sleep(15) # need to wait for the page to load completely
    browser.pdf(path: path, format: :A4)
    browser.quit
    {
      date: date,
      link: path,
      url: url,
      type: suffix
    }
  end

  def scrape
    source = CDC_PAGE
    response = connect_to(source)
    if response.status == 200
      download_to_pdf(source)     # return pdf_data
    else
      raise "Status site #{source} return: #{response.status}"
    end
  end

  def put_all_to_aws
    @s3 = AwsS3.new(bucket_key = :loki, account=:loki)
    Dir["#{storehouse}store/*"].map do |file|
      key_filename = file.split('/').last
      key = "tasks/scrape_tasks/st0#{Hamster::project_number}/#{key_filename}"
      body = File.read(file)
      aws_link = @s3.put_file(body, key)
      {file: file, aws_link: aws_link}
    end
  end

  def clear(aws_links)
    aws_links.each {|el| FileUtils.rm el[:file] }
  end
end
