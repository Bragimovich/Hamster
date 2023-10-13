
# The module CaptchaAdapter contains all the code for the 2captcha.com APIs, captchas.io APIs.
# Written by William Devries on Feb 21, 2023
require_relative 'lib/client'
require_relative 'lib/capsolver_client'
require_relative 'lib/errors'
require_relative 'lib/http'
require_relative 'lib/models/captcha'
require_relative 'lib/models/captcha_statistics'

module Hamster
  module CaptchaAdapter
    VERSION = '1.0.0'
    USER_AGENT = "CaptchaAdapter/Ruby v#{VERSION}"
    ADAPTERS = [:two_captcha_com, :captchas_io, :azcaptcha_com, :capsolver_com]
    DB_STATISTIC_ENABLED = true
    def self.new(key = :two_captcha_com, options = {})
      if key == :capsolver_com
        CaptchaAdapter::CapsolverClient.new(key, options)
      else
        CaptchaAdapter::Client.new(key, options)
      end
    end
  end
end


