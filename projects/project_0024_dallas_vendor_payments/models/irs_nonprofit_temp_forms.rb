# frozen_string_literal: true

class IrsNonprofitTempForms < ActiveRecord::Base
  establish_connection(Storage[host: :db01, db: :usa_raw].merge(local_infile: true))

  # pub_78
  def self.get_pub_78(limit)
    raw = self.connection.select_all ("SELECT ein, deductibility_code FROM irs_nonprofit_pub_78_temp WHERE LENGTH(ein) = 9 LIMIT #{[limit, 1000].min}")

    res = []
    raw.each { |r| res << r }

    res
  end

  def self.delete_pub_78(raw)
    self.connection.execute ("DELETE FROM irs_nonprofit_pub_78_temp WHERE ein IN (#{raw.map {|r| r['ein']}.flatten.join(',')})")
  end

  # auto_rev_list
  def self.get_auto_rev_list(limit)
    raw = self.connection.select_all ("SELECT id, ein, exemption_type, revocation_date, revocation_posting_date, exemption_reinstatement_date FROM irs_nonprofit_auto_rev_list_temp WHERE LENGTH(ein) = 9 LIMIT #{[limit, 1000].min}")

    res = []
    raw.each { |r| res << r }

    res
  end

  def self.delete_auto_rev_list(raw)
    self.connection.execute ("DELETE FROM irs_nonprofit_auto_rev_list_temp WHERE id IN (#{raw.map {|r| r['id']}.flatten.join(',')})")
  end

  # auto_rev_list
  def self.get_990n(limit)
    raw = self.connection.select_all ("SELECT ein, tax_period_year, f_col, tax_period_start, tax_period_end, website_url, principal_officer_name, principal_officer_street, principal_officer_city, principal_officer_state, principal_officer_zip, mailing_address_street, mailing_address_city, mailing_address_state, mailing_address_zip FROM irs_nonprofit_990n_temp WHERE LENGTH(ein) = 9 AND principal_officer_country = 'US' AND mailing_address_country = 'US' LIMIT #{[limit, 1000].min}")

    res = []
    raw.each { |r| res << r }

    res
  end

  def self.delete_990n(raw)
    self.connection.execute ("DELETE FROM irs_nonprofit_990n_temp WHERE ein IN (#{raw.map {|r| r['ein']}.flatten.join(',')})")
  end

  # auto_rev_list
  def self.get_990s(limit)
    raw = self.connection.select_all ("SELECT ein, filing_type, tax_period, return_fill_date, return_type, return_link_id FROM irs_nonprofit_990s_temp WHERE LENGTH(ein) >= 8 and return_type in ('990ER','990EOA','990OA','990PA','990A','990EA','990R','990T','990PR','990EO','990PF','990O','990EZ','990') LIMIT #{[limit, 1000].min}")

    res = []
    raw.each { |r| res << r }

    res
  end

  def self.delete_990s(raw)
    self.connection.execute ("DELETE FROM irs_nonprofit_990s_temp WHERE ein IN ('#{raw.map {|r| r['ein']}.flatten.uniq.join("','")}')")
  end
end
