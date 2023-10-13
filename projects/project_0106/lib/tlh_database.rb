require_relative '../models/texas_license_holders'
require_relative '../models/texas_license_holders_alternate_names'
require_relative '../models/texas_license_holders_sponsors'

def put_holders(holders)
  p '_________'
  p holders
  holder_tlh = TexasLicenseHolders.new do |i|
    i.holder_name =    holders[:holder_name]
    i.license_number = holders[:license_number]
    i.license_type =   holders[:license_type]
    i.license_link = holders[:link]
    i.status =  holders[:status]
    i.expiration_date = DateTime.strptime(holders[:expiration_date], "%m/%d/%Y")
    i.city = holders[:city]
    i.state = holders[:state]
    i.zip =    holders[:zip]
    i.county = holders[:county]
    i.md5_hash = holders[:md5_hash]
    i.run_id = holders[:run_id]
  end
  holder_tlh.save
end

def get_existing_license_number(license_numbers)
  existing_lic_n = []
  TexasLicenseHolders.where(license_number:license_numbers).each { |line| existing_lic_n.push(line.license_number) }
  existing_lic_n
end

def put_alternate_names(holder_id, alternate_name)
  p '_________'
  holder_tlh = TexasLicenseHoldersAlternateNames.new do |i|
    i.holder_id =      holder_id
    i.alternate_name = alternate_name
  end
  holder_tlh.save
end



def get_holder_id_by_lic_id(license_number)
  TexasLicenseHolders.where(license_number: license_number)[0].id
end

def get_holder_info_by_lic_id(license_number)
  TexasLicenseHolders.where(license_number: license_number)[0]
end

def put_sponsors(sponsor)
  p '_________'
  p sponsor
  sponsor_tlh = TexasLicenseHoldersSponsors.new do |i|
    i.holder_id =    sponsor[:holder_id]
    i.role = sponsor[:role].strip
    i.name = sponsor[:name]
    i.sponsor_date = sponsor[:sponsor_date]
    i.license_number =    sponsor[:license_number]
    i.license_type =    sponsor[:license_type]
    i.sponsor_link = sponsor[:link]
    i.expiration_date =  sponsor[:expiration_date]
    i.business_address =    sponsor[:business_address]
    i.business_city_state_zip =    sponsor[:business_city_state_zip]
    i.md5_hash = sponsor[:md5_hash]
  end
  sponsor_tlh.save
end

def get_existing_broker_links(links)
  existing_links = []
  TexasLicenseHoldersSponsors.where(sponsor_link:links).each { |line| existing_links.push(line.sponsor_link) }
  existing_links
end

def exist_md5_hash(md5_hash)
  TexasLicenseHolders.where(md5_hash: md5_hash)[0]
end

def exist_md5_hash_sponsor(md5_hash)
  TexasLicenseHoldersSponsors.where(md5_hash: md5_hash)[0]
end

def put_run_id_lic_ids(run_id, existing_lic_ids)
  holder = TexasLicenseHolders.find_by(license_number: existing_lic_ids)
  holder.run_id = run_id
  holder.save
end

def put_delete_for_lic(lic_number)
  holder = TexasLicenseHolders.find_by(license_number: lic_number)
  holder.deleted = 1
  holder.save
end

def deleted_for_not_equal_run_id(run_id)
  holder = TexasLicenseHolders.where.not(touched_run_id:run_id)
  holder.deleted = 1
  holder.save
end


def existing_broker_links_expiration_date(links)
  existing_links = []
  expiration_date_now = Date.today()-30
  TexasLicenseHoldersSponsors.where(sponsor_link:links).where("expiration_date < ?", expiration_date_now).each { |line| existing_links.push(line.sponsor_link) }
  existing_links
end


def put_run_id_broker_links(run_id, existing_broker_links)
  holder = TexasLicenseHoldersSponsors.find_by(sponsor_link: existing_broker_links)
  return if holder.nil?
  holder.run_id = run_id
  holder.save
end

def put_delete_for_lic_broker(lic_number)
  holder = TexasLicenseHoldersSponsors.find_by(license_number: lic_number)
  holder.deleted = 1
  holder.save
end

def deleted_for_not_equal_run_id_broker(run_id)
  holder = TexasLicenseHoldersSponsors.where.not(touched_run_id:run_id)
  holder.deleted = 1
  holder.save
end


def get_md5_broker(broker_links)
  exist_md5_hash_broker = []
  expiration_date_now = Date.today()-31
  TexasLicenseHoldersSponsors.where(sponsor_link:broker_links).where("expiration_date > ?", expiration_date_now).each { |line| exist_md5_hash_broker.push(line.md5_hash) }
  exist_md5_hash_broker
end
