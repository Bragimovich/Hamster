require_relative '../lib/message_send'
require_relative '../models/arrestees'
require_relative '../models/ids'
require_relative '../models/addresses'
require_relative '../models/aliases'
require_relative '../models/arrests'
require_relative '../models/charges'
require_relative '../models/bonds'
require_relative '../models/hearings'
require_relative '../models/facilities'
require_relative '../models/mugshots'
require_relative '../models/runs'

class Keeper < Hamster::Scraper
  def initialize
    super
    @s3 = AwsS3.new(:hamster, :hamster)
  end

  def add_run(status)
    Runs.insert({status: status})
  end
  def get_run
    Runs.select('id').to_a.last[:id]
  end

  def upd_run(status)
    Runs.last.update({status: status})
  end

  def add_arrestee(arrestee, run_id, index, md5_hash)
    check = Arrestees.where("full_name = \"#{arrestee[:full_name]}\" AND birthdate = \"#{arrestee[:birthdate]}\" AND race = \"#{arrestee[:race]}\" AND sex = \"#{arrestee[:sex]}\"").to_a
    if check.blank?
      Arrestees.insert(arrestee.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
      logger.info "[#{index}][#{md5_hash}] ARRESTEE ADD IN DATABASE!".green
    else
      check = Arrestees.where("full_name = \"#{arrestee[:full_name]}\" AND birthdate = \"#{arrestee[:birthdate]}\" AND race = \"#{arrestee[:race]}\" AND sex = \"#{arrestee[:sex]}\" AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Arrestees.where("full_name = \"#{arrestee[:full_name]}\" AND birthdate = \"#{arrestee[:birthdate]}\" AND race = \"#{arrestee[:race]}\" AND sex = \"#{arrestee[:sex]}\" AND deleted = 0").update({deleted: 1})
        logger.info "[#{index}][#{md5_hash}] OLD ARRESTEE DELETED = 1 IN DATABASE!".red
        deleted_arrestees(arrestee)
        Arrestees.insert(arrestee.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
        logger.info "[#{index}][#{md5_hash}] ARRESTEE ADD IN DATABASE!".green
      else
        Arrestees.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        logger.info "[#{index}][#{md5_hash}] ARRESTEE IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def deleted_arrestees(arrestee)
    arrestee_id = Arrestees.where("full_name = \"#{arrestee[:full_name]}\" AND birthdate = \"#{arrestee[:birthdate]}\" AND race = \"#{arrestee[:race]}\" AND sex = \"#{arrestee[:sex]}\" AND deleted = 1").to_a.last[:id]
    Addresses.where("arrestee_id = '#{arrestee_id}' AND deleted = 0").update({deleted: 1})
    Aliases.where("arrestee_id = '#{arrestee_id}' AND deleted = 0").update({deleted: 1})
    Ids.where("arrestee_id = '#{arrestee_id}' AND deleted = 0").update({deleted: 1})
    Mugshots.where("arrestee_id = '#{arrestee_id}' AND deleted = 0").update({deleted: 1})
    Arrests.where("arrestee_id = '#{arrestee_id}' AND deleted = 0").update({deleted: 1})
    arrests = Arrests.where("arrestee_id = '#{arrestee_id}' AND deleted = 1").to_a
    arrests.each do |arrest|
      arrest_id = arrest[:id]
      Bonds.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
      Facilities.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
      Charges.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
    end
  end

  def get_arrestee_id(md5_hash)
    Arrestees.where("md5_hash = '#{md5_hash}'").to_a.last['id']
  end

  def add_id(id, run_id)
    md5_hash = Digest::MD5.hexdigest(id.to_s)
    check = Ids.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Ids.insert(id.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id }))
      logger.info "  [+] ID ADD IN DATABASE!".green
    else
      Ids.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      logger.info "  [-] ID IS ALREADY IN DATABASE!".yellow
    end
  end

  def add_address(address, run_id)
    md5_hash = Digest::MD5.hexdigest(address.to_s)
    check = Addresses.where("arrestee_id = '#{address[:arrestee_id]}'").to_a
    if check.blank?
      Addresses.insert(address.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      logger.info "  [+] ADDRESSE ADD IN DATABASE!".green
    else
      check = Addresses.where("arrestee_id = '#{address[:arrestee_id]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Addresses.where("arrestee_id = '#{address[:arrestee_id]}' AND deleted = 0").update({deleted: 1})
        logger.info "  [-] OLD ADDRESSE DELETED = 1 IN DATABASE!".red
        Addresses.insert(address.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
        logger.info "  [+] ADDRESSE ADD IN DATABASE!".green
      else
        Addresses.where("arrestee_id = '#{address[:arrestee_id]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        logger.info "  [-] ADDRESSE IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_alias(aliase, run_id)
    md5_hash = Digest::MD5.hexdigest(aliase.to_s)
    check = Aliases.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Aliases.insert(aliase.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      logger.info "  [+] ALIASE ADD IN DATABASE!".green
    else
      Aliases.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      logger.info "  [-] ALIASE IS ALREADY IN DATABASE!".yellow
    end
  end

  def add_mugshot(mugshot, run_id)
    md5_hash = Digest::MD5.hexdigest(mugshot.to_s)
    check = Mugshots.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Mugshots.insert(mugshot.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id }))
      logger.info "  [+] MUGSHOT ADD IN DATABASE!".green
    else
      Mugshots.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      logger.info "  [-] MUGSHOT IS ALREADY IN DATABASE!".yellow
    end
  end

  def get_aws_link(link)
    aws_link = Mugshots.where("original_link = '#{link}'")
    aws_link.blank? ? nil : aws_link.to_a[0]['aws_link']
  end

  def save_to_aws(link)
    key_start = "crime_perps_mugshots/il/champaign/"
    url_login = 'https://portal-ilchampaign.tylertech.cloud/JailSearch/Login.aspx'
    browser = Dasher.new(using: :hammer, pc: 1).connect
    browser.go_to(url_login)
    browser.go_to(link)
    file_name = link.gsub(/&.+$/,'')[link.index(/[^?]+?$/), link.length].gsub('=','_')
    file_name += '.png'
    aws_link = nil
    FileUtils.mkdir_p("/home/hamster/HarvestStorehouse/project_0505/store/screens")
    if browser.body.include?('<img')
      browser.screenshot(path: "/home/hamster/HarvestStorehouse/project_0505/store/screens/#{file_name}", selector: 'img')
      key = key_start + file_name
      body = File.open("/home/hamster/HarvestStorehouse/project_0505/store/screens/#{file_name}")
      aws_link = @s3.put_file(body, key, metadata={ url: link })
      logger.info "+ PHOTO LOAD IN AWS!".green
      FileUtils.mv("/home/hamster/HarvestStorehouse/project_0505/store/screens/#{file_name}", "/home/hamster/HarvestStorehouse/project_0505/trash/#{file_name}")
    end
    browser.quit
    aws_link
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
  ensure
    Process.waitall
    GC.start(immediate_sweep: false)
  end

  def add_arrest(arrest, run_id)
    md5_hash = Digest::MD5.hexdigest(arrest.to_s)
    check = Arrests.where("booking_number = '#{arrest[:booking_number]}' AND arrestee_id = '#{arrest[:arrestee_id]}'").to_a
    if check.blank?
      Arrests.insert(arrest.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      logger.info "  [+] ARREST ADD IN DATABASE!".green
    else
      check = Arrests.where("booking_number = '#{arrest[:booking_number]}' AND arrestee_id = '#{arrest[:arrestee_id]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Arrests.where("booking_number = '#{arrest[:booking_number]}' AND arrestee_id = '#{arrest[:arrestee_id]}' AND deleted = 0").update({deleted: 1})
        deleted_arrests(arrest[:booking_number], arrest[:arrestee_id])
        logger.info "  [-] OLD ARREST DELETED = 1 IN DATABASE!".red
        Arrests.insert(arrest.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
        logger.info "  [+] ARREST ADD IN DATABASE!".green
      else
        Arrests.where("booking_number = '#{arrest[:booking_number]}' AND arrestee_id = '#{arrest[:arrestee_id]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        logger.info "  [-] ARREST IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def deleted_arrests(booking_number, arrestee_id)
    arrest_id = Arrests.where("booking_number = '#{booking_number}' AND arrestee_id = '#{arrestee_id}' AND deleted = 1").to_a.last[:id]
    Bonds.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
    Facilities.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
    Charges.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
  end

  def get_arrest_id(booking_number, arrestee_id)
    Arrests.where("booking_number = '#{booking_number}' AND arrestee_id = '#{arrestee_id}'").to_a.last['id']
  end

  def add_facility(facility, run_id)
    md5_hash = Digest::MD5.hexdigest(facility.to_s)
    check = Facilities.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Facilities.insert(facility.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      logger.info "    [+] FACILITY ADD IN DATABASE!".green
    else
      Facilities.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      logger.info "    [-] FACILITY IS ALREADY IN DATABASE!".yellow
    end
  end

  def add_charge(charge, run_id, md5_hash)
    check = Charges.where("arrest_id = #{charge[:arrest_id]} AND md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Charges.insert(charge.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      logger.info "    [+] CHARGE ADD IN DATABASE!".green
    else
      Charges.where("arrest_id = '#{charge[:arrest_id]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      logger.info "    [-] CHARGE IS ALREADY IN DATABASE!".yellow
    end
  end

  def get_charge_id(arrest_id, md5_hash)
    Charges.where("arrest_id = '#{arrest_id}' AND md5_hash = '#{md5_hash}'").to_a.last['id']
  end

  def add_bond(bond, run_id)
    md5_hash = Digest::MD5.hexdigest(bond.to_s)
    check = Bonds.where("arrest_id = #{bond[:arrest_id]} AND charge_id = '#{bond[:charge_id]}'").to_a
    if check.blank?
      Bonds.insert(bond.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      logger.info "    [+] BOND ADD IN DATABASE!".green
    else
      check = Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND charge_id = '#{bond[:charge_id]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND charge_id = '#{bond[:charge_id]}' AND deleted = 0").update({deleted: 1})
        logger.info "    [-] OLD BOND DELETED = 1 IN DATABASE!".red
        Bonds.insert(bond.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
        logger.info "    [+] BOND ADD IN DATABASE!".green
      else
        Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND charge_id = '#{bond[:charge_id]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        logger.info "    [-] BOND IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def get_booking_numbers(year)
    Facilities.connection.execute("SELECT DISTINCT booking_number FROM il_champaign__holding_facilities AS hf JOIN il_champaign__arrests AS a ON a.id = hf.arrest_id WHERE actual_release_date IS NULL AND YEAR(booking_date) != #{year}")
  end
end
