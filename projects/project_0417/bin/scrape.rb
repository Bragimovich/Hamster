require_relative '../lib/us_tax_exem_org_manager'

def scrape(options)
  manager = USTaxExemOrgManager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  elsif options[:parse_other]
    manager.parse_other
  end
end