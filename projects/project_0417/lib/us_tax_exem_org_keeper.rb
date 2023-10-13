require_relative '../models/us_tax_exem_org_runs'
require_relative '../models/us_tax_exem_org'
require_relative '../models/us_tax_exem_org_executives'
require_relative '../models/us_tax_exem_org_broken_link'

class USTaxExemOrgKeeper
  def initialize
    super
    @run_id = run.run_id
    @count  = 0
  end

  attr_reader :run_id, :count

  def finish
    run.finish
  end

  def status=(new_status)
    run.status = new_status
  end

  def save_broken_link(org)
    org[:broken_link] = org.delete(:link)
    md5 = MD5Hash.new(columns: org.keys)
    md5.generate(org)
    org.merge!({ md5_hash: md5.hash, run_id: run_id })
    USTaxExemOrgBrokenLink.store(org)
  end

  def save_org(org)
    executives = org.delete(:executives)
    executives.each { |i| i[:data_source_url] = org[:data_source_url] }
    keys = org.keys
    keys.delete(:street_address)
    # in the DB, md5_hashes have already been created without taking into account the :street_address key
    md5      = MD5Hash.new(columns: keys)
    md5_hash = md5.generate(org)
    org.merge!({ md5_hash: md5_hash, run_id: run_id })
    us_tax_exem_org = USTaxExemOrg.find_by(name: org[:name], state: org[:state], deleted: 0)
    if us_tax_exem_org && us_tax_exem_org.md5_hash == org[:md5_hash]
      org_id = us_tax_exem_org.id
    else
      @old_org_id = us_tax_exem_org&.id
      us_tax_exem_org&.update(deleted: 1)
      USTaxExemOrg.store(org)
      org_id = USTaxExemOrg.find_by(md5_hash: md5_hash).id
    end
    executives.each { |i| i[:org_id] = org_id }
    save_executives(executives) if executives.any?
    @count += 1
  end

  def save_executives(executives)
    org_id         = @old_org_id || executives[0][:org_id]
    executives_db  = USTaxExemOrgExecutives.where(org_id: org_id, deleted: 0)
    old_md5_hashes = executives_db.pluck(:md5_hash)
    new_md5_hashes = []
    executives.each do |executive|
      md5 = MD5Hash.new(columns: executive.keys)
      md5.generate(executive)
      md5_hash = md5.hash
      new_md5_hashes << md5_hash
      executive.merge!({ md5_hash: md5_hash, run_id: run_id })
    end
    hashes_write = new_md5_hashes - old_md5_hashes
    hashes_del   = old_md5_hashes - new_md5_hashes
    executives_db.each { |model| model.update(deleted: 1) if hashes_del.include?(model.md5_hash) }
    executives.each { |i| USTaxExemOrgExecutives.store(i) if hashes_write.include?(i[:md5_hash]) }
  end

  private

  def run
    RunId.new(USTaxExemOrgRuns)
  end
end
