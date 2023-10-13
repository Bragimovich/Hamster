require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @s3 = AwsS3.new(bucket_key = :us_court)
    @parser = Parser.new
  end

  def get_cookie(url)
    hamster = connect_to(url, proxy_filter: @proxy_filter)
    view_state, view_state_gen = @parser.parse_view_state(hamster)
    cookie = hamster&.headers['set-cookie'].to_s
    [cookie, view_state, view_state_gen]
  end

  def table_info(url, cookie, req, page)
    hamster = connect_to(url, proxy_filter: @proxy_filter, headers: { cookie: cookie }, req_body: req, method: :post)
    raise "Status #{hamster&.status}" if hamster&.status != 200
    @parser.parse_table_info(hamster, page)
  rescue StandardError => e
    message = "Error: #{e.message}\nBacktrace:#{e.backtrace}".red
    logger.error message
  end

  def pdf(link, court_path, case_id)
    link_find = connect_to(link, proxy_filter: @proxy_filter)
    return if link_find.blank?
    link_original = nil
    name = nil
    if link_find.status == 302
      link_original = link
      link = link_find.headers['location'].to_s.strip
    end
    unless link_find.body.blank?
      cobble = Dasher.new(:using=>:cobble)
      pdf_file = cobble.get(link)
      name = Digest::MD5.hexdigest(case_id).to_s
      name += '.pdf'
      sub_folder = "#{court_path}_PDF"
      unless pdf_file.blank?
        peon.put(file: name, subfolder: sub_folder, content: pdf_file)
        logger.info "PDF File #{name} save!".green
        peon.move_and_unzip_temp(file: name, from: "#{sub_folder}/", to: "#{sub_folder}/")
        logger.info "PDF File #{name} move & unzip!".yellow
      end
    end
    [name, link_original, link]
  end
end
