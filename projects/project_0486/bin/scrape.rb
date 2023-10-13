# frozen_string_literal: true

require_relative '../lib/manager_lake'

def scrape(options)
  puts <<~GREETING
    If you see this message, then the project's setup went good.

    The variable `options` contains the list of passed arguments. Right now,
    it contains the following:
  GREETING

  pp options

  puts <<~GREETING
    If you need to pass some specific arguments, you can do it using usual format:

      --argument

    or

      --argument=value

    The first one will contain `true` as value, the second will contain passed value.

    Now you can open and edit the `scraper.rb` file at your project's directory,
    according to your task.
  GREETING

  ManagerLake.new(options)


end

