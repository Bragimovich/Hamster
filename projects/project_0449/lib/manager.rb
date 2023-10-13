require_relative '../lib/keeper'
require_relative '../lib/project_parser'
require_relative '../lib/scraper'
require_relative '../lib/converter'
require_relative '../models//ms_mississippi_bar'
require_relative '../models//ms_mississippi_bar_runs'

class Manager < Hamster::Harvester

  SEARCH_URL = "https://courts.ms.gov/bar/barroll/brsearch.php".freeze
  URL = "https://courts.ms.gov/bar/barroll/brdetail.php".freeze
  HEADERS = {
    content_type: 'application/x-www-form-urlencoded',
    connection: 'keep-alive',
    host: 'courts.ms.gov',
    cookie: 'PHPSESSID=mfrq46c11lm83vdufms49o6qt2; cookiesession1=678A8C3377C21807C77E7429990D4F97'
  }.freeze

  def initialize(**params)
    super
    @keeper = Keeper.new(MsMississippiBar)
    @runs = RunId.new(MsMississippiBarRuns)
    @run_id = @runs.run_id
    fix_touched_run_id
    @scraper = Scraper.new
    @parser = ProjectParser.new
    @converter = Converter.new
  end

  def fix_touched_run_id
    @keeper.fix_empty_touched_run_id(@run_id)
  end

  def download
    ('a'..'z').each do |letter|
      form_data = "lname=&fname=&city=&zip1=&alpha=#{letter}"
      html = @scraper.body(
        url: SEARCH_URL,
        use: 'connect_to',
        ssl_verify: false,
        method: :post,
        req_body: form_data,
        headers: HEADERS
      )
      @parser.html = html
      attorneys = @parser.parse_attorneys
      md5_sum = @converter.to_md5(attorneys)
      filename = "letter_#{letter.to_s}_#{md5_sum}.html"
      save_html(@parser.html, filename, md5_sum)
      onclick_values = @parser.onclick_values
      next if onclick_values.nil?
      save_attorneys(onclick_values, attorneys, letter)
    end
    on_finish
  end

  def save_attorneys(onclick_values, attorneys, letter)
    onclick_values.map.with_index do |value, i|
      number = value.delete("^0-9")
      form_data_in = "brnum=#{number}"
      html = @scraper.body(
        url: URL,
        use: 'connect_to',
        ssl_verify: false,
        method: :post,
        req_body: form_data_in,
        headers: HEADERS
      )
      @parser.html = html
      data = @parser.parse_attorney_info(attorneys[i])
      md5 = @converter.to_md5(data)
      filename = "letter_#{letter.to_s}_row_#{md5}.html"
      save_html(@parser.html, filename, md5)
      data.merge!(
        md5_hash: md5,
        run_id: @run_id,
        touched_run_id: @run_id
      )
      data = @converter.clean_data(data)
      puts "full_data = #{data}"
      @keeper.insert(data, md5)
    end
  end

  def html_list
    html_arr = []
    peon.give_list.each do |filename|
      ('a'..'z').each do |letter|
        html_arr << peon.give(file: filename) if filename.include? "letter_#{letter}"
      end
    end
    html_arr
  end

  def save_html(html, filename, md5_sum)
    peon.put(content: html.to_html.to_s, file: filename) unless peon.give_list.include?(md5_sum) || html.blank?
  end

  def on_finish
    #@parser.unique_columns(html_list)
    @keeper.update_touched_run_id(@run_id)
    @keeper.update_deleted(@run_id)
    @runs.finish
  end
end
