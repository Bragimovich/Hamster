# frozen_string_literal: true

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}
CURRENT_PDF = '../current.pdf'

require 'zip'

class Scraper < Hamster::Scraper
  def initialize
    safe_connection { super }
    @peon = Peon.new(storehouse)
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  def pdf_to_txt(file_path)
    logger.info("#{STARS}\n#{file_path}")
    path = file_path.split('store/').first
    tmp_file_path = path + "processing_now.pdf"
    FileUtils.cp(file_path, tmp_file_path)
    Docsplit.extract_text(tmp_file_path, {pdf_opts: '-layout', output: path })
    File.read(tmp_file_path.sub('.pdf', '.txt'))
  end

  def download(links)
    links.each do |html_link, pdf_link|
      file_name = pdf_link.split('=')[2].sub('&', '.')
      begin
        get_file(pdf_link, file_name)
        @peon.put(content: get_source(html_link).body, file: file_name, subfolder: 'gz')
      rescue => e
        logger.error(e)
      end
    end
  end

  def dockets_info(file_path)
    res = @peon.give(file: File.basename(file_path), subfolder: 'gz')
  end

  def pdf_list
    pdf_files = Dir[storehouse + "store/*.pdf"].sort
    pdf_files.delete_if {|el| el.include?(TEST_CASE)}
  end

  # need to implement safe_connection
  def get_source(url)
    safe_connection { connect_to(url: url) }
  end

  # need to implement safe_connection
  def get_file(url, file_name)
    safe_connection { connect_to(url: url, method: :get_file, filename: storehouse+"store/" + file_name, headers: HEADERS) }
  end

  def store_all_to_csv(rec)
    FileUtils.mkdir_p "#{storehouse}store/csv"
    return nil if rec.nil? or rec.empty?
    store_to_csv([rec[:info]], 'case_info.csv')
    store_to_csv(rec[:relations_info_pdf], 'case_relations_info_pdf.csv')
    store_to_csv(rec[:parties], 'case_party.csv')
    store_to_csv(rec[:activities], 'case_activities.csv')
    store_to_csv(rec[:pdfs_on_aws], 'case_pdfs_on_aws.csv')
    store_to_csv(rec[:additional_info], 'case_additional_info.csv')
    store_to_csv(rec[:relations_activity_pdf], 'case_relations_activity_pdf.csv')
  end

  def store_to_csv(source, file_name)
    path = "#{storehouse}store/csv/#{file_name}"
    CSV.open(path, 'a') do |csv|
      source.each do |record|
        csv << record.values
      end
    end
  end

  # need to implement safe_connection -- implemented in get_source() and in get_file()
  def save_to_aws(url_file, key_start)
    # body = get_source(url_file)&.body
    # key = key_start + Time.now.to_i.to_s + '.pdf'
    # res = @s3.put_file(body, key, metadata={url: url_file})

    # 1. alternative download using method: :get_file; filename - 'current.pdf'
    get_file(url_file, CURRENT_PDF)
    key = key_start + Time.now.to_i.to_s + '.pdf'

    # 2. upload to aws using suggested method (https://stackoverflow.com/questions/29105178/uploading-large-file-to-s3-with-ruby-fails-with-out-of-memory-error-how-to-read)
    res = nil
    file_path = "#{storehouse}store/#{CURRENT_PDF}"
    File.open(file_path, 'rb') do |file|
      res = @s3.put_file(file, key, metadata={url: url_file})
    end

    # 3. delete file after uploading
    FileUtils.rm Dir[file_path]

    res
  end

  def clear
    sleep(5)
    name = Time.now.to_s.gsub(':', '-').split[0..1].join(' ')
    zipfile_name = "#{storehouse}trash/#{name}.zip"
    folder = "#{storehouse}store/"
    touch_dir("#{folder}/csv")
    touch_dir("#{folder}/gz")

    Zip::File.open(zipfile_name, create: true) do |zip|
      peon.list.each do |filename|
        zip.add(filename, File.join(folder, filename))
      end
      peon.list(subfolder: 'csv/').each do |filename|
        zip.add(filename, File.join("#{folder}csv/", filename))
      end
      peon.list(subfolder: 'gz/').each do |filename|
        zip.add(filename, File.join("#{folder}gz/", filename))
      end
    end
    FileUtils.rm Dir["#{folder}*.pdf"]
    FileUtils.rm Dir["#{folder}csv/*.csv"]
    FileUtils.rm Dir["#{folder}gz/*.gz"]
  end

  def touch_dir(dir)
    Dir.mkdir(dir) unless Dir.exists?(dir)
  end

  # ========================= check this out =============================
  def safe_connection(retries=10)
    begin
      yield if block_given?
    rescue *CONNECTION_ERROR_CLASSES => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.warn(e.class)
        logger.warn("#{STARS}Reconnect!#{STARS}")
        sleep 100
        Hamster.report(to: OLEKSII_KUTS, message: "project-#{Hamster::project_number} Scraper: Reconnecting...")
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *CONNECTION_ERROR_CLASSES => e
        retry
      end
      retry
    end
  end
end
