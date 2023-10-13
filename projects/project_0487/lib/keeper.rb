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

  def update_run(status)
    Runs.last.update({status: status})
  end

  def add_arrestee(arrestee, run_id, index)
    md5_hash = Digest::MD5.hexdigest(arrestee.to_s)
    check = Arrestees.where("data_source_url = '#{arrestee[:data_source_url]}'").to_a
    if check.blank?
      Arrestees.insert(arrestee.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
      puts "[#{index}][#{arrestee[:data_source_url]}] ARRESTEE ADD IN DATABASE!".green
    else
      check = Arrestees.where("data_source_url = '#{arrestee[:data_source_url]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Arrestees.where("data_source_url = '#{arrestee[:data_source_url]}' AND deleted = 0").update({deleted: 1})
        puts "[#{index}][#{arrestee[:data_source_url]}] OLD ARRESTEE DELETED = 1 IN DATABASE!".red
        deleted_arrestees(arrestee[:data_source_url])
        Arrestees.insert(arrestee.merge({run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id}))
        puts "[#{index}][#{arrestee[:data_source_url]}] ARRESTEE ADD IN DATABASE!".green
      else
        Arrestees.where("data_source_url = '#{arrestee[:data_source_url]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        puts "[#{index}][#{arrestee[:data_source_url]}] ARRESTEE IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def deleted_arrestees(data_source_url)
    arrestee_id = Arrestees.where("data_source_url = '#{data_source_url}' AND deleted = 1").to_a[-1][:id]
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
      charges = Charges.where("arrest_id = '#{arrest_id}' AND deleted = 1").to_a
      charges.each do |charge|
        charge_id = charge[:id]
        Hearings.where("charge_id = '#{charge_id}' AND deleted = 0").update({deleted: 1})
      end
    end
  end

  def get_arrestee_id(data_source_url)
    Arrestees.where("data_source_url = '#{data_source_url}'").to_a.last[:id]
  end

  def add_id(id, run_id)
    md5_hash = Digest::MD5.hexdigest(id.to_s)
    check = Ids.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Ids.insert(id.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id }))
      puts "  [+] ID ADD IN DATABASE!".green
    else
      Ids.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      puts "  [-] ID IS ALREADY IN DATABASE!".yellow
    end
  end

  def add_address(address, run_id)
    md5_hash = Digest::MD5.hexdigest(address.to_s)
    check = Addresses.where("arrestee_id = '#{address[:arrestee_id]}'").to_a
    if check.blank?
      Addresses.insert(address.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      puts "  [+] ADDRESSE ADD IN DATABASE!".green
    else
      check = Addresses.where("arrestee_id = '#{address[:arrestee_id]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Addresses.where("arrestee_id = '#{address[:arrestee_id]}' AND deleted = 0").update({deleted: 1})
        puts "  [-] OLD ADDRESSE DELETED = 1 IN DATABASE!".red
        Addresses.insert(address.merge({ run_id: run_id, md5_hash: md5_hash, touched_run_id: run_id }))
        puts "  [+] ADDRESSE ADD IN DATABASE!".green
      else
        Addresses.where("arrestee_id = '#{address[:arrestee_id]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        puts "  [-] ADDRESSE IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def add_alias(aliase, run_id)
    md5_hash = Digest::MD5.hexdigest(aliase.to_s)
    check = Aliases.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Aliases.insert(aliase.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      puts "  [+] ALIASE ADD IN DATABASE!".green
    else
      Aliases.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      puts "  [-] ALIASE IS ALREADY IN DATABASE!".yellow
    end
  end

  def add_mugshot(mugshot, run_id)
    md5_hash = Digest::MD5.hexdigest(mugshot.to_s)
    check = Mugshots.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Mugshots.insert(mugshot.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      puts "  [+] MUGSHOT ADD IN DATABASE!".green
    else
      Mugshots.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      puts "  [-] MUGSHOT IS ALREADY IN DATABASE!".yellow
    end
  end

  def get_aws_link(link)
    aws_link = Mugshots.where("original_link = '#{link}'")
    aws_link.blank? ? nil : aws_link.to_a[0]['aws_link']
  end

  def save_to_aws(link)
    key_start = "crime_perps_mugshots/il/kendall/"
    cobble = Dasher.new(:using=>:cobble, ssl_verify: false)
    body = cobble.get(link)
    file_name = link.gsub(/\?.+$/,'')[link.index(/[^\/]+?$/), link.length]
    file_name += '.jpg'
    key = key_start + file_name
    aws_link = @s3.put_file(body, key, metadata={ url: link })
    puts "  [+] PHOTO LOAD IN AWS!".green
    aws_link
  end

  def add_arrest(arrest, run_id)
    md5_hash = Digest::MD5.hexdigest(arrest.to_s)
    check = Arrests.where("booking_number = '#{arrest[:booking_number]}' AND arrestee_id = '#{arrest[:arrestee_id]}'").to_a
    if check.blank?
      Arrests.insert(arrest.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      puts "  [+] ARREST ADD IN DATABASE!".green
    else
      check = Arrests.where("booking_number = '#{arrest[:booking_number]}' AND arrestee_id = '#{arrest[:arrestee_id]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Arrests.where("booking_number = '#{arrest[:booking_number]}' AND arrestee_id = '#{arrest[:arrestee_id]}' and deleted = 0").update({deleted: 1})
        deleted_arrests(arrest[:booking_number], arrest[:arrestee_id])
        puts "  [-] OLD ARREST DELETED = 1 IN DATABASE!".red
        Arrests.insert(arrest.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
        puts "  [+] ARREST ADD IN DATABASE!".green
      else
        Arrests.where("booking_number = '#{arrest[:booking_number]}' AND arrestee_id = '#{arrest[:arrestee_id]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        puts "  [-] ARREST IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def deleted_arrests(booking_number, arrestee_id)
    arrest_id = Arrests.where("booking_number = '#{booking_number}' AND arrestee_id = '#{arrestee_id}' AND deleted = 1").to_a[-1][:id]
    Bonds.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
    Facilities.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
    Charges.where("arrest_id = '#{arrest_id}' AND deleted = 0").update({deleted: 1})
    charges = Charges.where("arrest_id = '#{arrest_id}' AND deleted = 1").to_a
    charges.each do |charge|
      charge_id = charge[:id]
      Hearings.where("charge_id = '#{charge_id}' AND deleted = 0").update({deleted: 1})
    end
  end

  def get_arrest_id(booking_number, arrestee_id)
    Arrests.where("booking_number = '#{booking_number}' AND arrestee_id = '#{arrestee_id}'").to_a.last['id']
  end

  def add_facility(facility, run_id)
    md5_hash = Digest::MD5.hexdigest(facility.to_s)
    check = Facilities.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Facilities.insert(facility.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      puts "    [+] FACILITY ADD IN DATABASE!".green
    else
      Facilities.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      puts "    [-] FACILITY IS ALREADY IN DATABASE!".yellow
    end
  end

  def add_total_bond(bond, run_id)
    md5_hash = Digest::MD5.hexdigest(bond.to_s)
    check = Bonds.where("arrest_id = #{bond[:arrest_id]} AND bond_category = '#{bond[:bond_category]}'").to_a
    if check.blank?
      Bonds.insert(bond.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      puts "    [+] #{bond[:bond_category]} ADD IN DATABASE!".green
    else
      check = Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND bond_category = '#{bond[:bond_category]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND bond_category = '#{bond[:bond_category]}' AND deleted = 0").update({deleted: 1})
        puts "    [-] OLD #{bond[:bond_category]} DELETED = 1 IN DATABASE!".red
        Bonds.insert(bond.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
        puts "    [+] #{bond[:bond_category]} ADD IN DATABASE!".green
      else
        Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND bond_category = '#{bond[:bond_category]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        puts "    [-] #{bond[:bond_category]} IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def get_charge_id_bond(bond_number,arrest_id)
    charge_id = Charges.where("arrest_id = '#{arrest_id}' AND bond_number LIKE '%#{bond_number}%'")
    charge_id.blank? ? nil : charge_id.to_a.last['id']
  end

  def add_charge(charge, offense_time, run_id)
    md5_hash = Digest::MD5.hexdigest(charge.to_s)
    check = Charges.where("arrest_id = #{charge[:arrest_id]} AND number = '#{charge[:number]}'").to_a
    if check.blank?
      Charges.insert(charge.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id, offense_time: offense_time}))
      puts "    [+] CHARGE ADD IN DATABASE!".green
    else
      check = Charges.where("arrest_id = '#{charge[:arrest_id]}' AND number = '#{charge[:number]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Charges.where("arrest_id = '#{charge[:arrest_id]}' AND number = '#{charge[:number]}' AND deleted = 0").update({deleted: 1})
        deleted_charges(charge[:arrest_id], charge[:number])
        puts "    [-] OLD CHARGE DELETED = 1 IN DATABASE!".red
        Charges.insert(charge.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id, offense_time: offense_time}))
        puts "    [+] CHARGE ADD IN DATABASE!".green
      else
        Charges.where("arrest_id = '#{charge[:arrest_id]}' AND number = '#{charge[:number]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        puts "    [-] CHARGE IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def deleted_charges(arrest_id, number)
    charge_id = Charges.where("arrest_id = '#{arrest_id}' AND number = '#{number}' AND deleted = 1").to_a.last['id']
    Hearings.where("charge_id = '#{charge_id}' AND deleted = 0").update({deleted: 1})
  end

  def get_charge_id(charge, arrest_id)
    Charges.where("arrest_id = '#{arrest_id}' AND number = '#{charge}'").to_a.last['id']
  end

  def add_hearing(hearing, court_time, run_id)
    md5_hash = Digest::MD5.hexdigest(hearing.to_s)
    check = Hearings.where("md5_hash = '#{md5_hash}'").to_a
    if check.blank?
      Hearings.insert(hearing.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id, court_time: court_time}))
      puts "    [+] HEARING ADD IN DATABASE!".green
    else
      Hearings.where("md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
      puts "    [-] HEARING IS ALREADY IN DATABASE!".yellow
    end
  end

  def add_bond(bond, run_id)
    md5_hash = Digest::MD5.hexdigest(bond.to_s)
    check = Bonds.where("arrest_id = #{bond[:arrest_id]} AND charge_id = '#{bond[:charge_id]}' AND bond_number = '#{bond[:bond_number]}'").to_a
    if check.blank?
      Bonds.insert(bond.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
      puts "    [+] BOND ADD IN DATABASE!".green
    else
      check = Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND charge_id = '#{bond[:charge_id]}' AND bond_number = '#{bond[:bond_number]}' AND md5_hash = '#{md5_hash}'").to_a
      if check.blank?
        Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND charge_id = '#{bond[:charge_id]}' AND bond_number = '#{bond[:bond_number]}' AND deleted = 0").update({deleted: 1})
        puts "    [-] OLD BOND DELETED = 1 IN DATABASE!".red
        Bonds.insert(bond.merge({md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id}))
        puts "    [+] BOND ADD IN DATABASE!".green
      else
        Bonds.where("arrest_id = '#{bond[:arrest_id]}' AND charge_id = '#{bond[:charge_id]}' AND bond_number = '#{bond[:bond_number]}' AND md5_hash = '#{md5_hash}' AND deleted = 0").update({touched_run_id: run_id})
        puts "    [-] BOND IS ALREADY IN DATABASE!".yellow
      end
    end
  end

  def missing_pages(run_id)
    Arrestees.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Arrests.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Addresses.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Aliases.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Bonds.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Charges.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Facilities.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Hearings.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Ids.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
    Mugshots.where("touched_run_id != #{run_id} AND deleted = 0").update({deleted: 1})
  end
end
