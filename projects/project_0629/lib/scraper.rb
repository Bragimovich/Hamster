# frozen_string_literal: true

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}

require 'zip'

class Scraper < Hamster::Scraper
  def initialize
    super
    @peon = Peon.new(storehouse)
    @s3 = AwsS3.new(bucket_key = :us_court)
    @processing_now = "#{storehouse}store/processing_now.pdf"
  end

  def get_source(url)
    connect_to(url: url).body
  end

  def store(api_link)
    file_name = api_link.split('p17027').last.sub('/id/', '_')
    @peon.put(content: get_source(api_link), file: file_name, subfolder: 'gz')
  end

  def next_file
    @peon.give_any(subfolder: 'gz')
  end

  def drop(file_name)
    @peon.move(file: file_name, from: 'gz', to: 'removed')
  end

  def adjourn(file_name)
    @peon.move(file: file_name, from: 'gz', to: 'unprocessed')
  end

  def store_pdf(link)
    file_name = link.split('p17027').last.sub('/id/', '_').sub('/download', '.pdf')
    file_path = "#{storehouse}store/#{file_name}"
    connect_to(link, method: :get_file, filename: file_path)
    @processing_now#file_path
  end

  def pdf_list
    @peon.list.map {|name| "#{storehouse}store/#{name}"}
  end
end
__END__
  def pdf_to_txt(file_path)
    puts '*'*77, file_path
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
      rescue => error
        p error
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

  def get_file(url, file_name)
    connect_to(url: url, method: :get_file, filename: storehouse+"store/" + file_name, headers: HEADERS)
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

  def save_to_aws(url_file, key_start)
      cobble = Dasher.new(:using=>:cobble)
      body = cobble.get(url_file)
      key = key_start + Time.now.to_i.to_s + '.pdf'
      res = @s3.put_file(body, key, metadata={url: url_file})
  end

  def clear
    sleep(5)
    name = Time.now.to_s.gsub(':', '-').split[0..1].join(' ')
    zipfile_name = "#{storehouse}trash/#{name}.zip"
    folder = "#{storehouse}store/"

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
end
