require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/message_send'

class Manager < Hamster::Scraper

  def initialize
    super
    @keeper = Keeper.new
    @scraper = Scraper.new
    @parser = Parser.new
  end

  def download
    @keeper.add_run('download start!')
    year = Date.today.year
    index = 1
    blank_count = 0
    (index..).each do |index|
      bookingnumber = "#{"#{year}".last(2)}#{"#{index}".rjust(5,'0')}"
      cookie = get_cookie
      url_search = 'https://justice.peoriacounty.gov/JailingSearch.aspx?ID=400'
      headers_search = headers_search_post(cookie)
      hamster_search = @scraper.page(url_search, headers_search)
      viewstate, viewstategenerator, eventvalidation = get_params(hamster_search)
      req_body = req_body(viewstate, viewstategenerator, eventvalidation, bookingnumber)
      headers_search_post = headers_search_post(cookie)
      hamster_search_post = @scraper.page_post(url_search, headers_search_post, req_body)
      profile_links = @parser.profile_links(hamster_search_post)
      if profile_links.blank? && blank_count < 15
        blank_count += 1
        logger.info "NEXT! #{blank_count}".red
        next
      elsif profile_links.blank? && blank_count >= 15
        break
      else
        blank_count = 0
      end
      url_profile = "https://justice.peoriacounty.gov/#{profile_links[0]['href']}"
      save_profile(url_profile, headers_search_post, year.to_s)
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.info message
      message_send(message)
    end
    check_old_years
    @keeper.upd_run('download finish!')
    message_send('Download finish!')
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def check_old_years
    year = Date.today.year
    booking_numbers = @keeper.get_booking_numbers(year)
    booking_numbers.each do |bookingnumber|
      bookingnumber = bookingnumber.to_a[0]
      cookie = get_cookie
      url_search = 'https://justice.peoriacounty.gov/JailingSearch.aspx?ID=400'
      headers_search = headers_search_post(cookie)
      hamster_search = @scraper.page(url_search, headers_search)
      viewstate, viewstategenerator, eventvalidation = get_params(hamster_search)
      req_body = req_body(viewstate, viewstategenerator, eventvalidation, bookingnumber)
      headers_search_post = headers_search_post(cookie)
      hamster_search_post = @scraper.page_post(url_search, headers_search_post, req_body)
      profile_links = @parser.profile_links(hamster_search_post)
      url_profile = "https://justice.peoriacounty.gov/#{profile_links[0]['href']}"
      subfolder = 'check'
      save_profile(url_profile, headers_search_post, subfolder)
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
  end

  def save_profile(url_profile, headers_search_post, subfolder)
    hamster_profile = @scraper.page(url_profile, headers_search_post)
    content = @parser.body_content(hamster_profile)
    content = "<p><b>data_source_url: </b><a class='original_link' href='#{url_profile}'>#{url_profile}</a></p>" + content
    file = url_profile.strip[url_profile.index(/[^=]+$/),url_profile.length]
    file = "#{file}.html"
    peon.put(file: file, subfolder: subfolder, content: content)
    logger.info "File save! #{file}".green
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def get_cookie
    url_login = 'https://justice.peoriacounty.gov/login.aspx'
    hamster_login = @scraper.page_login(url_login)
    cookie = hamster_login&.headers['set-cookie']
    cookie = cookie.gsub('path=/;','').gsub('secure;','').gsub('HttpOnly,','').gsub('.ASPXFORMSPUBLICACCESS=;','')
    cookie = cookie.gsub('expires=Tue, 12-Oct-1999 05:00:00 GMT;','').gsub(/; expires.+$/,'').squeeze(' ').strip
    cookie
  end

  def get_params(hamster_search)
    viewstate = url_decode(@parser.viewstate(hamster_search))
    viewstategenerator = @parser.viewstategenerator(hamster_search)
    eventvalidation = url_decode(@parser.eventvalidation(hamster_search))
    [viewstate, viewstategenerator, eventvalidation]
  end

  def req_body(viewstate, viewstategenerator, eventvalidation, bookingnumber)
    req_body = '__EVENTTARGET=&'
    req_body += '__EVENTARGUMENT=&'
    req_body += "__VIEWSTATE=#{viewstate}&"
    req_body += "__VIEWSTATEGENERATOR=#{viewstategenerator}&"
    req_body += "__EVENTVALIDATION=#{eventvalidation}&"
    req_body += 'RadioSearchType=0&'
    req_body += "BookingNumber=#{bookingnumber}&"
    req_body += 'LastName=&'
    req_body += 'FirstName=&'
    req_body += 'MiddleName=&'
    req_body += 'DateOfBirth=&'
    req_body += 'DateBookingOnAfter=&'
    req_body += 'DateBookingOnBefore=&'
    req_body += 'DateReleasedOnAfter=&'
    req_body += 'DateReleasedOnBefore=&'
    req_body += 'BondStatusType=0&'
    req_body += 'DatePostedOnAfter=&'
    req_body += 'DatePostedOnBefore=&'
    req_body += 'SearchSubmit=Search&'
    req_body += 'SearchType=BookingNumber&'
    req_body += 'NameTypeKy=&'
    req_body += 'BaseConnKy=&'
    req_body += 'ShowInactive=&'
    req_body += 'StatusType=&'
    req_body += 'AllStatusTypes=&'
    req_body += 'BondCompany=&'
    req_body += "NodeID=#{url_decode('98,1500,2500,6100')}&"
    req_body += 'ProductType=&'
    params = url_decode("BookingNumberOption~~Search By:~~0~~Booking Number||BookingNumber~~Booking Number:~~#{bookingnumber}~~#{bookingnumber}")
    req_body += "SearchParams=#{params}"
    req_body
  end

  def headers_search(cookie)
    {
      "Host" => "justice.peoriacounty.gov",
      "Cookie" => cookie
    }
  end

  def headers_search_post(cookie)
    {
      "Host" => "justice.peoriacounty.gov",
      "Cookie" => cookie,
      "Referer" => "https://justice.peoriacounty.gov/JailingSearch.aspx?ID=400"
    }
  end

  def url_decode(item)
    item.gsub('/','%2F').gsub('=','%3D').gsub('+','%2B').gsub(',','%2C').gsub('~','%7E').gsub('|','%7C').gsub(':','%3A').gsub(' ','+')
  end

  def store
    index = 0
    @keeper.upd_run('store start!')
    run_id = @keeper.get_run
    year = Date.today.year.to_s
    [year, 'check'].each do |folder|
      files = peon.give_list(subfolder: folder)
      files.each do |file|
        index += 1
        file = file.sub(/\.gz$/, '')
        page = peon.give(file: file, subfolder: folder)
        inmate = @parser.page_parse(page)
        next if inmate.blank?
        arrestee = {
          full_name: inmate[:full_name],
          birthdate: inmate[:birthdate],
          race: inmate[:race],
          sex: inmate[:sex],
          height: inmate[:height],
          weight: inmate[:weight],
          data_source_url: inmate[:data_source_url]
        }
        md5_hash = Digest::MD5.hexdigest(arrestee.to_s)
        @keeper.add_arrestee(arrestee, run_id, index, md5_hash)
        arrestee_id = @keeper.get_arrestee_id(md5_hash)
        id = {
          arrestee_id: arrestee_id,
          number: inmate[:so_number],
          type: "SO #",
          data_source_url: inmate[:data_source_url]
        }
        @keeper.add_id(id, run_id)
        address = {
          arrestee_id: arrestee_id,
          full_address: inmate[:full_address],
          street_address: inmate[:street_address],
          city: inmate[:city],
          state: inmate[:state],
          zip: inmate[:zip],
          data_source_url: inmate[:data_source_url]
        }
        @keeper.add_address(address, run_id)
        aliases = inmate[:aliases]
        aliases.each do |name|
          aliase = {
            arrestee_id: arrestee_id,
            full_name: name.strip,
            data_source_url: inmate[:data_source_url]
          }
          @keeper.add_alias(aliase, run_id)
        end
        mugshots = inmate[:mugshots]
        mugshots.each do |item|
          aws_link = @keeper.get_aws_link(item)
          aws_link = @keeper.save_to_aws(item) if aws_link.blank?
          mugshot = {
            arrestee_id: arrestee_id,
            aws_link: aws_link,
            original_link: item
          }
          @keeper.add_mugshot(mugshot, run_id)
        end
        arrest = {
          arrestee_id: arrestee_id,
          booking_date: inmate[:booking_date],
          booking_agency: inmate[:booking_agency],
          booking_number: inmate[:booking_number],
          data_source_url: inmate[:data_source_url]
        }
        @keeper.add_arrest(arrest, run_id)
        arrest_id = @keeper.get_arrest_id(inmate[:booking_number], arrestee_id)
        facility = {
          arrest_id: arrest_id,
          facility: inmate[:facility],
          start_date: inmate[:booking_date],
          actual_release_date: inmate[:release_date],
          data_source_url: inmate[:data_source_url]
        }
        @keeper.add_facility(facility, run_id)
        booking_charges = inmate[:charges]
        booking_charges.each do |item|
          charge = {
            arrest_id: arrest_id,
            disposition: item[:disposition],
            description: item[:charge],
            offense_date: item[:offense_date],
            data_source_url: inmate[:data_source_url]
          }
          md5_hash = Digest::MD5.hexdigest(charge.to_s)
          @keeper.add_charge(charge, run_id, md5_hash)
          charge_id = @keeper.get_charge_id(arrest_id, md5_hash)
          bond = {
            arrest_id: arrest_id,
            charge_id: charge_id,
            bond_category: 'Surety Bonds',
            bond_type: item[:bond_type],
            bond_amount: item[:bond_amount],
            data_source_url: inmate[:data_source_url]
          }
          @keeper.add_bond(bond, run_id) unless item[:bond_amount].blank?
        end
        peon.move(file: file, from: folder)
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
        message_send(message)
      end
    end
    peon.throw_trash
    peon.throw_temps
    @keeper.upd_run('store finish!')
    message_send('Store finish!')
  end
end
