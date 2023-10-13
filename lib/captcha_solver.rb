# frozen_string_literal: true
module Hamster
  class CaptchaSolver < TwoCaptcha::Client
    def initialize(key = :general, **options)
      two_captcha_tokens = Storage.new.two_captcha
      if two_captcha_tokens.keys.include?(key.to_s)
        key = two_captcha_tokens[key]
      elsif key.to_s.length != 32
        raise ArgumentError, "Wrong key to token or wrong token to captcha solver.
              The token must be 32 characters long or your config doesn't have keys for captcha solver.
              Please, check your config file."
      end
      super(key, options)
    end
  end
end