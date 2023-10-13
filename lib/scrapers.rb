# frozen_string_literal: true

class Scrapers < ActiveRecord::Base
  storage = Storage.use(host: :db02, db: :hle_resources)
  establish_connection(storage) if storage
end
