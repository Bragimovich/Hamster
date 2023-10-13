require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  URLS = {"georgia" => "https://gabar.reliaguide.com/","indiana" => "https://inbar.reliaguide.com/","michigan" => "https://sbm.reliaguide.com/","nebraska" => "https://nebar.reliaguide.com/","illinois" => "https://isba.reliaguide.com/"}

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end

  def download(state)
    download_status = keeper.get_download_status(state)
    unless (download_status)
      scraper = Scraper.new
      url = URLS[state]
      @index = 1
      @subfolder_path = create_subfolder(state)
      downloaded_files = peon.give_list(subfolder: @subfolder_path).sort.reverse
      (downloaded_files.empty?)? last_name_start_letter = 'A' : last_name_start_letter = downloaded_files[0][2] rescue nil
      (downloaded_files.empty?)? first_name_start_letter = 'A' : first_name_start_letter = downloaded_files[0][0] rescue nil
      (downloaded_files.empty?)? @pattern = '' : @pattern = downloaded_files.first.split('_').last.gsub('.gz','') rescue nil
      (downloaded_files.empty?)? @flag = 1 : @flag = 0
      (first_name_start_letter..'Z').each do |first_name|
        (last_name_start_letter..'Z').each do |last_name|
          html, check_next = get_next_check(scraper, downloaded_files, first_name, last_name, url)
          next if (html == [] || html.body == "[]")
          if check_next
            get_last_name_pattern(scraper, first_name, last_name, downloaded_files, url,state)
          else
            saving_inner_pages(html.body,scraper,state)
            save_file(html.body, "#{first_name}_#{last_name}", @subfolder_path)
          end
        end
        last_name_start_letter = 'A'
      end
      keeper.update_download_status(state)
    end
  end

  def store
    download_status_array = []
    states = peon.list(subfolder: "#{keeper.run_id}").sort
    states.each do |state|
      @state = state
      error_count = 0
      download_status = keeper.get_download_status(state)
      download_status_array.append(download_status)
      if (download_status)
        md5_array = keeper.get_inserted_md5(state)
        domain = get_domain(state)
        files = peon.list(subfolder: "#{keeper.run_id}/#{state}").sort
        files.each do |file|
          data_array = []
          next unless file.include? '.gz'
          outer_page = (peon.give(subfolder: "#{keeper.run_id}/#{state}/",file: "#{file}"))
          ids_and_urls = parser.parse_page(outer_page).map{|data_hash| [data_hash['id'],data_hash['vanityURL'].gsub(' ','%20')]}
          ids_and_urls.each do |array|
            begin
              @id = array.first.to_s
              profile_html = get_page_body(domain,URI.escape(array.last))
              sections_html = get_page_body(domain,"#{id}/profile-sections?sort=sectionName,asc")
              education_html = get_page_body(domain,"#{id}/profile-educations?sort=dateStarted,desc")
              license_html = get_page_body(domain,"#{id}/profile-licenses?sort=rank,asc")
              category_html = get_page_body(domain,"#{id}/profile-categories?sort=rank,categoryName&size=50")
              next if (get_code_status(profile_html) || get_code_status(sections_html) || get_code_status(education_html) || get_code_status(license_html) || get_code_status(category_html))
              data_array << parser.parse_data(profile_html,sections_html,education_html,license_html,category_html,keeper.run_id,domain)
            rescue Exception => e
              error_count += 1
              if (error_count > 35)
                Hamster.report(to: 'Tauseeq Tufail', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
                error_count = 0
              end
            end
          end
          keeper.update_touch_id(state,parser.get_md5_array(data_array))
          data_array = data_array.reject{|data_hash| md5_array.include? data_hash[:md5_hash]}
          keeper.save_record(state,parser.delete_md5_key(data_array,:md5_hash))
        end
        keeper.mark_delete(state)
      end
    end
    keeper.finish unless (download_status_array.include? false)
  end

  private

  def get_code_status(page)
    return true if page.include? 'Internal Server Error'
    false
  end

  def get_domain(state)
    case state
    when 'georgia'
      'gabar'
    when 'indiana'
      'inbar'
    when 'michigan'
      'sbm'
    when 'nebraska'
      'nebar'
    when 'illinois'
      'isba'
    end
  end

  def get_page_body(domain,suffix)
    file_name = Digest::MD5.hexdigest "https://#{domain}.reliaguide.com/api/public/profiles/#{suffix}"
    peon.give(subfolder: "#{keeper.run_id}/#{state}/#{id}/",file: file_name) rescue "[]"
  end

  attr_accessor :keeper, :parser ,:state, :id

  def get_next_check(scraper, downloaded_files, first_name, prefix, url)
    tries = 0
    while tries < 10
      html = get_html(scraper, downloaded_files, first_name, prefix, url)
      check_next = html.headers[:link].split rescue nil
      break unless check_next.nil?
      tries += 1
    end
    (check_next[1].include? "next" rescue nil)? check = true : check = false
    [html, check]
  end

  def saving_inner_pages(body,scraper,state)
    domain = get_domain(state)
    lawyers_array = parser.parse_page(body)
    lawyers_array.each do |data_hash|
      already_downloaded_ids = peon.list(subfolder: "#{keeper.run_id}/#{state}/")
      next if already_downloaded_ids.include? data_hash['id'].to_s
      vanity_url = data_hash['vanityURL'].gsub(' ','%20')
      id = data_hash['id']
      apis_array = ["#{URI.escape(vanity_url)}","#{id}/profile-sections?sort=sectionName,asc",
        "#{id}/profile-educations?sort=dateStarted,desc","#{id}/profile-licenses?sort=rank,asc",
        "#{id}/profile-categories?sort=rank,categoryName&size=50"]
      apis_array.each do |key|
        link = get_api_link(domain,key)
        response = scraper.connect_to(link)
        file_name = Digest::MD5.hexdigest link
        save_file(response.body,file_name,"#{keeper.run_id}/#{state}/#{data_hash['id']}")
      end
    end
  end

  def get_api_link(domain,key)
    "https://#{domain}.reliaguide.com/api/public/profiles/#{key}"
  end

  def get_last_name_pattern(scraper, first_name, last_name, downloaded_files, url,state)
    get_deep_search(last_name).each do |prefix|
      @flag = 1 if @pattern == prefix
      next if ((@pattern[@index] != prefix.last) && (@flag ==0))
      html, check_next = get_next_check(scraper, downloaded_files, first_name, prefix, url)
      if html.class == Faraday::Response
        next if (html.body.empty?) || (html.body == "[]")
      else
        next if (html.empty?) || (html.body == "[]") 
      end
      if check_next
        @index += 1 if @flag == 0
        get_last_name_pattern(scraper, first_name, prefix, downloaded_files, url,state)
      else
        saving_inner_pages(html.body,scraper,state)
        save_file(html.body, "#{first_name}_#{prefix}", @subfolder_path)
      end
    end
  end

  def get_html(scraper, downloaded_files, first_name, last_name, url)
    file_name = "#{first_name}_#{last_name}"
    return [] if (downloaded_files.include? "#{file_name}.gz")
    scraper.get_outer_page(url, first_name, last_name)
  end

  def get_deep_search(letter)
    ('A'..'Z').map{|l| "#{letter}#{l}"}
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def create_subfolder(state)
    data_set_path = "#{storehouse}store/#{keeper.run_id}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path = "#{data_set_path}/#{state}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path.split("store/").last
  end

end
