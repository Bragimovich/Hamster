# frozen_string_literal: true

class Runs < ActiveRecord::Base
  self.table_name = 'covid_19_vaccination_runs'
  establish_connection(Storage[host: :db01, db: :usa_raw])

  def self.last_run
    self.all.to_a.last
  end

  def self.processing(id)
    self.update(id, {status: 'processing'})
  end

  def self.pause(id)
    self.update(id, {status: 'pause'}) if id
  end

  def self.error(id)
    self.update(id, {status: 'error'}) if id
  end

  def self.scraped(id)
    self.update(id, {status: 'scraped'}) if id
  end

end
