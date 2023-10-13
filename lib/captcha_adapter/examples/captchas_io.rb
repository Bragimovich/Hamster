
class CaptchasIoTest
  
  def self.get_balance
    Hamster.logger.debug "Testing get_balance() of captchas.io API"
    adapter = :captchas_io
    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    Hamster.logger.debug "Balance: #{captcha_client.balance}".yellow
  end

  def self.decode_image
    Hamster.logger.debug "Testing decode_image() of captchas.io API"
    adapter = :captchas_io
    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end
    captcha = captcha_client.decode_image!(url: 'https://raw.githubusercontent.com/infosimples/two_captcha/master/captchas/1.png')
    Hamster.logger.debug "Captcha Text solved by #{adapter}: #{captcha.text}, Captcha ID: #{captcha.id}"

    # Outputs Ex: Captcha Text solved by captchas_io: infosimles, Captcha ID: 25748747
  end

  def self.decode_recaptcha_v2
    Hamster.logger.debug "Testing decode_recaptcha_v2() of captchas.io API"
    options = {
      pageurl: "https://search.dupagesheriff.org/inmate/list",
      googlekey: "6LdIiCMUAAAAAMpEP6dAar-s2YxT4JQNUUMzqHHm"
    }
    adapter = :captchas_io

    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    Hamster.logger.debug "#{adapter} balance: #{captcha_client.balance}".yellow
    money = captcha_client.balance
    
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end
    
    captcha = captcha_client.decode_recaptcha_v2!(options)
    Hamster.logger.debug "Captcha Token solved by #{adapter}: #{captcha.text}, Captcha ID: #{captcha.id}"

    # Outputs: Captcha Token solved by captchas_io: 03AKH6MRGKRPKMnbFKI-uNREBHVNX4r-oFh6BcharXNJ_H3N33FxSBJLYVJ7erg9B-hBt_b48VB2A6dsAZsZZGTZX3VQX8z_wDm2ajo51QVy6Kxlp9LIBaYZm9iJ0WR_rOvTZp7SKdMikgI-Kl0T5VPjwoFMkFY9oRnCOxQQ4pfdcSZ-REWcKU-cIoa3Cv1uKCBIQDvupKIR2NtNENEqsB9hQb3ccmTKg1wbrHHNDq1-c0oVYh2TTJuCS822v7GZUjs3gVgLb5EOVapc9OmgCxWNsbScALqz22LMvf2weRVUUNHcJSovVzmA8o1R2YwBt6pA4lXYonSmwDutYzwWOhhgX5mLWIx1WwHX_gQ1-zdz30qvW9GLDpo5qE8bQ1GPeeWa0bnNhu-m3a-Zt2eKEZHaHJHzyk637wdeLldLBtU4WRYMECtI5CNB0uXRpIU6JTDRC-5jAjWgM6McYfF4wBLK7Mv28yLD8rng2K-R8VMfy2M9l1qLPXMWobkg8lp8XeiG-m52Mdy7TOm3TJTlkfKnN-1T-1kiHD2KWemQoBQPgrY-Z3oXCCYjBMypNjB0iLmITTS7F-BHMoyFPLmQ05A1pd8gWXje_B4QbTDf2IhC_FmAjDfc_5A8k, Captcha ID: 25749768
  end

  def self.decode_recaptcha_v2_invisible
    Hamster.logger.debug "Testing decode_recaptcha_v2() of captchas.io API when invisible option is true"
    options = {
      pageurl: "https://2captcha.com/demo/recaptcha-v2-invisible",
      googlekey: '6LdO5_IbAAAAAAeVBL9TClS19NUTt5wswEb3Q7C5',
      invisible: 1
    }
    adapter = :captchas_io
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout:200, polling:10)
    money = captcha_client.balance

    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end

    decoded_captcha = captcha_client.decode_recaptcha_v2!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by captchas_io: 03AKH6MRGb2apxUWT0iqaKOnlnv4-s70rEZMgnnG71CwMIDG4PTFsOT15bHgsuQmoCtotOov2llaAwXhSlXfVIOjB0Qt6DvGo6HNKVHfGkYD9sD3w4opi9lAYb2VZP6rdY6E_v8jXgoe6tBJddrkbJRFmC8P-x5vrVWwTSIW0dpAtRIjOOR13uFFwM62TtDA9w15vAKmW_JzcBBrwtiaxWZ0YLo3LNxtMzUZJH09dcX0MSYR-AWzDaKnsQVhFXr4lHMJ0-xZFK899pHXiIyC2njllQiL4nzzxhpGRbLmK0NcGzOr4UjpQ_tH2tr0FnHGzBXzKYGcMOm-0VCS9l4zBiIQvYG-RSMpNAHqFmZHq0haqLVwzjYpD1by_uCI7tvZRQGkWTO1RPLAXP1LqRKmvhfnpKrSOYl1bN3rKw29AvW_rsDgwctdoOw2QcftH7zlRPUg4MFMUhFx2APdnoqajquM2iw6n4kVsZk3HMDsN6PqeF2vTdac9qY2L3UnEpF7zBPZxPx9zDuKYaqh5t4oKCSJO3H3qIcMCobv20gj40GKrKXCCi3dSA9-aoUlOheKIwLp4ObPDQqQ-qIWuOL7_K9enVFsIxsw5jniTIEQyQQvYb82f_SjMdgN8
  end

  def self.decode_recaptcha_v3
    Hamster.logger.debug "Testing decode_recaptcha_v3() of captchas.io API"
    options = {
      googlekey: '6LfB5_IbAAAAAMCtsjEHEHKqcB9iQocwwxTiihJu',
      pageurl:   'https://2captcha.com/demo/recaptcha-v3',
      version: 'v3'
    }
    adapter = :captchas_io
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout: 200, polling: 10)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
    end
    decoded_captcha = captcha_client.decode_recaptcha_v3!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by captchas_io: 03AKH6MRGWXdm1b4e9UIJjSaPG9EOx7r2y3N8GLDfrmqsbECETa6CPmtblTrVRFeDxklucrmSsz_UB8W9vXZNz3VAogTneV2tQwyCj265xVWd_Bv80Udcy7WOJ2fMiYtbRwj10Xwl_eTQvxtpdYXiVdrrb5jLC1aj9FjOvHBu_22sE4zyA-d785PYfYNza7G1Z_czpPB5cNdOyK7mzTl4AsULBicFcXG_r5hxnKGYjJagUm_whMEcEz4kngt_4yeIbANmXSaYCXdXcRpMUnPJO7_xeu_3W6ZiY_fLK2QkhnqYByvZ22gvNK19MJrANu5aSiLcm-lpiz-rZlzd9FH-Fyg1GVGudwL6kLcE9ujay7FGDFa5kN2bNcbPD-rwlJFa-I8WSjW8f5lCW_x2G3K2BmrJARf2b4uEdeJFdQ-zw9J92Q6PoswGTG1sll_j3vEfYMWwcAEtzNL-N-Cwn7Vvu2Ml6X3LHJNvYQHSsHO9SMQno_XFbxJFopX-cWx8CHcVjPsmkS9IlwzBwfjxN0hGKkijMsgQYOc6nGfQ8p594dO8got72qKgVEWO1-iX0p6m2IUBDLHD2K5rc
  end

  def self.decode_hcaptcha
    Hamster.logger.debug "Testing decode_hcaptcha() of captchas.io API"
    options = {
      pageurl: "https://hcaptcha.com/",
      sitekey: '00000000-0000-0000-0000-000000000000'
    }
    adapter = :captchas_io
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
    Hamster.logger.debug "Testing turnstile() of captchas.io API"
    # url = "https://peet.ws/turnstile-test/non-interactive.html" # demo
    pageurl = "https://courtindex.sdcourt.ca.gov/CISPublic/namesearch/"
    sitekey = "0x4AAAAAAAAjq6WYeRDKmebM"
    
    adapter = :captchas_io
    
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout:200, polling:10)
    Hamster.logger.debug '-'*20, "#{adapter} Balance: #{captcha_client.balance.to_s}"
    decoded_captcha = captcha_client.turnstile!({sitekey: sitekey, pageurl: pageurl})
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: 
  end
  

end




