
class TwoCaptchaComTest
  
  def self.get_balance
    Hamster.logger.debug "Testing get_balance() of 2captcha.com API"
    adapter = :two_captcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    Hamster.logger.debug "Balance: #{captcha_client.balance}".yellow
  end

  def self.decode_image
    Hamster.logger.debug "Testing decode_image() of 2captcha.com API"
    adapter = :two_captcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end
    captcha = captcha_client.decode_image!(url: 'https://raw.githubusercontent.com/infosimples/two_captcha/master/captchas/1.png')
    Hamster.logger.debug "Captcha Text solved by #{adapter}: #{captcha.text}, Captcha ID: #{captcha.id}"

    # Outputs Ex: Captcha Text solved by two_captcha_com: infosimples, Captcha ID: 73307204374
  end

  def self.decode_recaptcha_v2
    Hamster.logger.debug "Testing decode_recaptcha_v2() of 2captcha.com API"
    options = {
      pageurl: "https://search.dupagesheriff.org/inmate/list",
      googlekey: "6LdIiCMUAAAAAMpEP6dAar-s2YxT4JQNUUMzqHHm"
    }
    adapter = :two_captcha_com

    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    Hamster.logger.debug "#{adapter} balance: #{captcha_client.balance}".yellow
    money = captcha_client.balance
    
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end
    
    captcha = captcha_client.decode_recaptcha_v2!(options)
    Hamster.logger.debug "Captcha Token solved by #{adapter}: #{captcha.text}, Captcha ID: #{captcha.id}"

    # Outputs: Captcha Token solved by two_captcha_com: 03AKH6MRHaenM3hypPxVW3Y9KGQrATfU8uvYK56go2poIKOLXhtaDba2dcWtqqoqGvveemwsJMXX4ztzCOJuxrvvSmo4cEXcT_0djxmIwEg_50J4uZBjAUZZKBv8nfurH4e9qYfhD_4xik-3cbI08iYVRbkKsyX4ePUE52ZCH1b6CodYky4D4_vnXy6C4ku3P-nnH9DvxVlk3Fds_RUmoq-fCIWOcylhRti9knRKpuFLpTg3W3slL-XYGyQlHwwkg09pisLXVmLcDcQNs3_q9YXuK4EDCOnrRCW26xM4183cfXKuv_1qzU4l9DCGMDJETaDFZp97evKLCpUJAYUMvMQ-ujrHKTXVU9IM1-X6z8-3H1OyEuvlfNnv5QY7DaCOeZ03mTjbP9ILADIn-SWjC30NGix5oJfPjSHufVzauTVKRgiOi9HuWgmOUmoMQqe4x8yqi23_QCIS5j4PKWcRi0uuW363aqwIp3IuxfeL9mMnvEf99ngR1MXWO5O-YZeqYKrVtHkzP5nEo23z-nBfnXPOPQu1ESoxu-gBOxw9TuHuhEpBfZoURaKtTUNklOa3Wvu9Ci3TQbqPPDmHSxqiwd2rUGC4lVXc2uwyvpuOIOCBko96D7fo7UCCo, Captcha ID: 73307234831
  end

  def self.decode_recaptcha_v2_invisible
    Hamster.logger.debug "Testing decode_recaptcha_v2() of 2captcha.com API when invisible option is true"
    options = {
      pageurl: "https://2captcha.com/demo/recaptcha-v2-invisible",
      googlekey: '6LdO5_IbAAAAAAeVBL9TClS19NUTt5wswEb3Q7C5',
      invisible: 1
    }
    adapter = :two_captcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout:200, polling:10)
    money = captcha_client.balance

    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end

    decoded_captcha = captcha_client.decode_recaptcha_v2!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by two_captcha_com: 03AKH6MRFIZDvWeZiekLXbFrEIE_HSK6TR3BtTUZ1BeefsekA8xNWSQKLIvG0d4vnppkAdqOG4TTP2rimdRjrfn9On2uEx2dSMgjWnlEUj7g8EfKbu_T7mIBIjx2Fe2bZfu2-VelVH1yNx-YHgqT4xNDOLyj-zwnvRXZnVObfjsTwTrzzcBNmpBrUFOfs-Pu1l2VTbByWVdP9Z7TIafzAuqtMl0pXhdpIeAdSkOYi7tIqYRBaRIvjkhhFIr4fn3ELWMoApALLKf33kf-M-9MmaorFaHCLeHaWT8Jw04wmULhSbexWq5PuoXiREoieYfqb2jJrlQ67xn9m2L0XN2X0u3JNetnqOL4UBsTJibTss3ouT2dypv4A9GHbOZDDDhs_sZImvjhzEujs6QGusYVu9Jn4GwuTPTQhFT-pUCwjibe-EkzI5UHWoWbdpd_0XsHR7Ghp2txjxptGPBLyqgSf8JUBctH6-PsqQqVlAw9BFH2H8LNBWl-bJ8Kmh6gTbU_eGCZKGvqWaMi0ezr83lr6vUvIDMObrKLmVQiXPsK2vYBdv9Klq6u_9YPXB7m0bSC-82JC680-yxzEfQFSbi2KEHgqXdBRLWU1WSw
  end

  def self.decode_recaptcha_v3
    Hamster.logger.debug "Testing decode_recaptcha_v3() of 2captcha.com API"
    options = {
      googlekey: '6LfB5_IbAAAAAMCtsjEHEHKqcB9iQocwwxTiihJu',
      pageurl:   'https://2captcha.com/demo/recaptcha-v3',
      version: 'v3'
    }
    adapter = :two_captcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout: 200, polling: 10)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
    end
    decoded_captcha = captcha_client.decode_recaptcha_v3!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by two_captcha_com: 03AKH6MRHYqoSRArugMSZF0Vk40riVXVwcHk8Rmf1_5t7UBtqpAkT4THy7_2PB1BnzmOniJUGLZkTu8ZCA3Yek6wYzVQyaN9xyJWgBeWYPO1vAXPASlEp4W2a2B0MTJTE4SXHQmcPhvVK9LYiT26RKNTbXrjdT_kSsO4CXp_rStg0YoHAleH2CoAD_sGNX1hSPWB7j5eKPqM8tgLkRynLLJAasVwa8QLO6I46oyv9ihiFkqBWjcWtKtHaGpMvVVTVEmuLS_qlqAug57KpknAszREiCdUYnbPzlYZXOXrqsGG9d61rrInIMSkoH2qZFuWC8B0qDX4gFPHaUnd4qRJVkePrJrBuMwj_cRF1ix9C8xJJEKC5oc_2_ZRnqx9ZUyd_ScTvMMImc6g4OoJSFZBD6ZNktwNoS5mAvCciySB9NzRfpP0CCH_7ShUqV5T8tzQTYHmHuh0VLFmaa-7jwRIXVptLTqTPAZqOlsmA5XAjxvBIbRLNeKAtfuNjr4J2ERh32bQgpX4foNZfU
  end

  def self.decode_hcaptcha
    Hamster.logger.debug "Testing decode_hcaptcha() of 2captcha.com API"
    options = {
      pageurl: "https://hcaptcha.com/",
      sitekey: '00000000-0000-0000-0000-000000000000'
    }
    adapter = :two_captcha_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout: 200, polling: 10)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
    end
    decoded_captcha = captcha_client.decode_hcaptcha!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by two_captcha_com: W1_eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.3gAFp3Bhc3NrZXnFAd94iiVKbDKzfJzVNNm2ubT668CQmEvXkL1QEzEmicWfN59q1iPGK7ND-XMbS3ML1eCbJbzkjknWhq7mFsIXp7BCR1dNRrIyNor1Di9VPQdmW9C26Gn7W2MyIzRbVT02kRUeIBzV1QEcGItb6mj0n_6tNtwZs0mBw4UCek8KeVGuhXWSPEQo6lRK3a6JL3l6msLS6cUZUcXUlL5Mk8eEeXM-1wQD7wdZHC8EynlVtEH7S2GSOI0rRtJQdtju2B-IJ35CwR2AKM9s2zWLjptOIR0BtJSmmP1TfNNyCacNAme1jN8sshrVZLAdxZelGO9oprpjLZGu-NSsnhPHrWW83YQKQ99dNJKzuGaZeg35AbAEetpZkBcld0HqZsq5tZK4Q9bLCjW40nCZ_0tyZL6HtINM5shsO11qY8_lfYsxxK6BPOTcg0sYsll_gfp1S_AeQTG5AZ1iXhPvWRVeiNb93dhdB93D01H6DWyMfUCmpxO-O7rDZPvVJVcsHxpVPYkzIDafgfYa3PWCwZihIGxjWFtGDPlSlxIDJbvcihelgM3fon1WjDvgzClqWYxnHRNmczmFGNF_dYdLlFJoV3HjfFEj3QqjLoFkJXD8jed71_khh0fk0sca9U-EKyEVaetcvKdzaXRla2V52SQwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDCjZXhwzmQyKXSicGQApWNkYXRh1AAA.vVtVuUEIrI4R0-8dku8gQl2vUGSyXMufULqi7J5n4Ro
  end

  def self.turnstile
    Hamster.logger.debug "Testing turnstile() of 2captcha.com API"
    # url = "https://peet.ws/turnstile-test/non-interactive.html" # demo
    pageurl = "https://courtindex.sdcourt.ca.gov/CISPublic/namesearch/"
    sitekey = "0x4AAAAAAAAjq6WYeRDKmebM"
    
    adapter = :two_captcha_com
    
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout:200, polling:10)
    Hamster.logger.debug '-'*20, "#{adapter} Balance: #{captcha_client.balance.to_s}"
    decoded_captcha = captcha_client.turnstile!({sitekey: sitekey, pageurl: pageurl})
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by two_captcha_com: 0.qdi1DebzASzLdpdlwlnc9mju9PDd8BCY79kECnr8nGuEDlJZ6yqgzHMa0tQwDSHAidG1XWFw9LZhiasjaJXsWN9B1yKwEJRGAxjD7_X2VUT24pRUc17NhRHGO2Eg4dFl9W6SFsSoVDoA-xYYrwEbU3t9xyXG5nfKDLeNNouyKOplk6nhG7sBmOQG_xOv3P9tQrxUQ7SCst8KvtUVcaO88ioUy3jff7wlUVk1zDByPfcGQASlXFq3hQKUY3zc63H3ITn0fdG-0AA5XH4c1OyeDFhrkYSKcje9cPM_VLG4mcSCYIeWVoBmiRAaACinUOQ18Hbz88wjRfq58RGvsVaT0fc6nWQf47Z6op8wpeBpuAk.MNnDFzrxGY7OG8dg8Cwh6Q.7158c8fc44625fdfddbe0ec34c80cbbdac0c0f53b590970b57516c731257cb21
  end

end




