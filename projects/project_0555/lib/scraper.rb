# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def download_page(url)
    retries = 0
    begin
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or retries == 10 or response&.status == 404
    [response , response&.status]
  end

  def pdf(link, court_path, case_id)
    link_find = connect_to(url: link, proxy_filter: @proxy_filter)
    return if link_find.blank?
    # link_original = nil
    name = nil
    if link_find.status == 302
      # link_original = link
      link = link_find.headers['Request URL'].to_s.strip
    end
    unless link_find.body.blank?
      cobble = Dasher.new(:using=>:cobble)
      pdf_file = cobble.get(link)
      name = Digest::MD5.hexdigest(case_id).to_s
      name += '.pdf'
      sub_folder = "#{court_path}"
      unless pdf_file.blank?
        peon.put(file: name, subfolder: sub_folder, content: pdf_file)
        peon.move_and_unzip_temp(file: name, from: "#{sub_folder}/", to: "#{sub_folder}/")
      end
    end
    name
  end
  
  def store_to_aws(pdf_file, file_name, link, court_id, case_id)
    key_start = "us_courts_expansion/#{court_id}/#{case_id}/"
    aws_link  = ''
    name = file_name
    name = change_name(name) if name.include? "\ "
    key  = key_start + name + '.pdf'

    File.open(pdf_file, 'rb') do |file|
      aws_link = @s3.put_file(file, key, metadata=
                                {
                                  url: link,
                                  case_id: case_id,
                                  court_id: court_id.to_s
                                }
                              )
    end
    aws_link
  end
  
  def change_name(name)
    name = name.gsub(/\s/, "_")
    name
  end
  
  def clear_folder(base_path)
    path_to_pdf_folder = "#{base_path}trash/*.pdf"
    Dir[path_to_pdf_folder].each do |filename|
      File.delete(filename) if File.exist?(filename)
    end
  end

end