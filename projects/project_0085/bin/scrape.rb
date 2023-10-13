# frozen_string_literal: true

LOCAL_HOST_DEV = ENV::has_key?("LOCAL_HOST_DEV")


require_relative 'manager'

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

  Manager.new(options).run
end

