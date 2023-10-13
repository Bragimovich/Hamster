
class AzcaptchaComTest

  def self.get_balance
    Hamster.logger.debug "Testing get_balance() of azcaptcha.com API"
    adapter = :azcaptcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    Hamster.logger.debug "Balance: #{captcha_client.balance}".yellow
  end

  def self.decode_image
    Hamster.logger.debug "Testing decode_image() of azcaptcha.com API"
    adapter = :azcaptcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end
    captcha = captcha_client.decode_image!(url: 'https://raw.githubusercontent.com/infosimples/two_captcha/master/captchas/1.png')
    Hamster.logger.debug "Captcha Text solved by #{adapter}: #{captcha.text}, Captcha ID: #{captcha.id}"

    # Outputs Ex: 
  end

  def self.decode_recaptcha_v2
    Hamster.logger.debug "Testing decode_recaptcha_v2() of azcaptcha.com API"
    options = {
      pageurl: "https://search.dupagesheriff.org/inmate/list",
      googlekey: "6LdIiCMUAAAAAMpEP6dAar-s2YxT4JQNUUMzqHHm"
    }
    adapter = :azcaptcha_com

    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    Hamster.logger.debug "#{adapter} balance: #{captcha_client.balance}".yellow
    money = captcha_client.balance
    
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end
    
    captcha = captcha_client.decode_recaptcha_v2!(options)
    puts "Captcha Token solved by #{adapter}: #{captcha.text}, Captcha ID: #{captcha.id}"

    # Outputs: 
  end

  def self.decode_recaptcha_v2_invisible
    Hamster.logger.debug "Testing decode_recaptcha_v2() of azcaptcha.com API when invisible option is true"
    options = {
      pageurl: "https://2captcha.com/demo/recaptcha-v2-invisible",
      googlekey: '6LdO5_IbAAAAAAeVBL9TClS19NUTt5wswEb3Q7C5',
      invisible: 1
    }
    adapter = :azcaptcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout:200, polling:10)
    money = captcha_client.balance

    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end

    decoded_captcha = captcha_client.decode_recaptcha_v2!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: 
  end

  def self.decode_recaptcha_v3
    Hamster.logger.debug "Testing decode_recaptcha_v3() of azcaptcha.com API"
    options = {
      googlekey: '6LfB5_IbAAAAAMCtsjEHEHKqcB9iQocwwxTiihJu',
      pageurl:   'https://2captcha.com/demo/recaptcha-v3',
      version: 'v3'
    }
    adapter = :azcaptcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout: 200, polling: 10)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
    end
    decoded_captcha = captcha_client.decode_recaptcha_v3!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: 
  end

  def self.decode_hcaptcha
    Hamster.logger.debug "Testing decode_hcaptcha() of azcaptcha.com API"
    options = {
      pageurl: "https://hcaptcha.com/",
      sitekey: '00000000-0000-0000-0000-000000000000'
    }
    adapter = :azcaptcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout: 200, polling: 10)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
    end
    decoded_captcha = captcha_client.decode_hcaptcha!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: 
  end

  def self.turnstile
    Hamster.logger.debug "Testing turnstile() of azcaptcha.com API"
    # url = "https://peet.ws/turnstile-test/non-interactive.html" # demo
    pageurl = "https://courtindex.sdcourt.ca.gov/CISPublic/namesearch/"
    sitekey = "0x4AAAAAAAAjq6WYeRDKmebM"
    
    adapter = :azcaptcha_com
    
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout:200, polling:10)
    Hamster.logger.debug '-'*20, "#{adapter} Balance: #{captcha_client.balance.to_s}"
    decoded_captcha = captcha_client.turnstile!({sitekey: sitekey, pageurl: pageurl})
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: 
  end
end




