# frozen_string_literal: true
require_relative '../lib/manager'


def scrape(options)
  answer = Manager.new(**options)
  puts answer
end

