# frozen_string_literal: true

require 'zip'

class Scraper < Hamster::Scraper
  def initialize
    super
  end

  def get_source(url)
    connect_to(url: url)
  end

  def download_csv(source)
    clear unless peon.list.empty?
    logger.info("#{STARS}\nDownload csv from #{source}")
    file_name = Hamster::Parser.new.storehouse + "store/" + Time.now.to_s.split[0] + "-il_prof_licenses.csv"
    connect_to(source, method: :get_file, filename: file_name, timeout: 300)
    file_name
  end

  def clear
    name = Time.now.to_s.gsub(':', '-').split[0..1].join(' ')
    folder = "#{storehouse}store/"
    zipfile_name = "#{storehouse}trash/#{name}.zip"
    Zip::File.open(zipfile_name, create: true) do |zip|
      peon.list.each do |filename|
        zip.add(filename, File.join(folder, filename))
      end
    end
    FileUtils.rm Dir["#{folder}*"]
    put_all_to_aws
  end

  def put_all_to_aws
    @s3 = AwsS3.new(bucket_key = :loki, account=:loki)
    Dir["#{storehouse}trash/*"].each do |file|
      key_filename = file.split('/').last.sub(' ', '-')
      key = "tasks/scrape_tasks/st0#{Hamster::project_number}/#{key_filename}"
      body = File.read(file)
      @s3.put_file(body, key)
      FileUtils.rm file
    end
  end
end
