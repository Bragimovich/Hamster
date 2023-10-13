# frozen_string_literal: true

module Hamster
  module HamsterTools

    def response_cookies(response)
      {'Cookie'=>response.headers['set-cookie']}
      # response.headers['set-cookie']&.collect{|ea| ea[/^.*?;/]}.join
    end
  end
end
