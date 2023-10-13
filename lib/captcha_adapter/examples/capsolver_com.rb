
class CapsolverComTest
  
  def self.get_balance
    Hamster.logger.debug "Testing get_balance() of capsolver.com API"
    adapter = :capsolver_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    Hamster.logger.debug "Balance: #{captcha_client.balance}".yellow
  end

  def self.decode_image
    Hamster.logger.debug "Testing decode_image() of capsolver.com API"
    adapter = :capsolver_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end
    captcha = captcha_client.decode_image!(url: "https://captcha.com/images/captcha/botdetect3-captcha-ancientmosaic.jpg")
    Hamster.logger.debug "Captcha Text solved by #{adapter}: #{captcha.text}, Captcha ID: #{captcha.id}"
    # Outputs Ex: Captcha Text solved by capsolver_com: w93bx, Captcha ID: 1b1d2276-dea0-4aa0-a32a-7356029a82a5
  end

  def self.decode_image_02
    client = Hamster::CaptchaAdapter.new(:capsolver_com)
    Hamster.logger.debug client.balance
    img = open("https://captcha.com/images/captcha/botdetect3-captcha-meltingheat.jpg")
    img_body = Base64.encode64(img.read)
    # :module could be either of "common" and "queueit", default is "common"
    captcha_response = client.decode_image!(body: img_body)
    Hamster.logger.debug captcha_response.inspect
    # Output Ex: #<Hamster::CaptchaAdapter::Captcha:0x000055b1d583c228 @id="192b2d96-a356-427c-b5b8-a364d6bc5d69", @api_response={"errorId"=>0, "status"=>"ready", "solution"=>{"confidence"=>0.9506, "text"=>"da3v8"}, "taskId"=>"192b2d96-a356-427c-b5b8-a364d6bc5d69"}, @text="da3v8">
  end

  def self.decode_recaptcha_v2
    Hamster.logger.debug "Testing decode_recaptcha_v2() of capsolver.com API"
    options = {
      pageurl: "https://search.dupagesheriff.org/inmate/list",
      googlekey: "6LdIiCMUAAAAAMpEP6dAar-s2YxT4JQNUUMzqHHm"
    }
    adapter = :capsolver_com

    captcha_client = Hamster::CaptchaAdapter.new(adapter)
    Hamster.logger.debug "#{adapter} balance: #{captcha_client.balance}".yellow
    money = captcha_client.balance
    
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end
    
    captcha = captcha_client.decode_recaptcha_v2!(options)
    Hamster.logger.debug "Captcha Token solved by #{adapter}: #{captcha.text}, Captcha ID: #{captcha.id}"

    # Outputs: Captcha Token solved by capsolver_com: 03AKH6MRHYbKoKjOGME0nXsZenI_4nAmKNiQm2MuiU0zQVlxqSQCFLzPS-54ghJPt4qS8KHhEykFtZWjMqP2rgOZDi1UKfPizCtgogSrqug0Vgkubb9LqwjIfVQtvRrQzGKYkWJhgzNdx40lCONFrLvW_eVINtVVzAye_xh18TL8l-og4sSe-EgZPlKdGjG88NVTWyZBvn3i1ncluouM1JD1AgberJPpvOJDV21CXIKBQFNAp4f38MxTp_OElmPdB1cakdnkzGgK8HtBE9daU94bRotvHMSbHT8x4OQlH9du-4806LbWTxSg5MYMGApMJNX7KJNw8uk7coY6mEvYtqqGXTMJONjLew2XZjM0LTYigU1xID3cp42UsSK88nBCf99r7qWBqJ8Rp-_oyh6aua12HPRiMgYKrFecsMYoZaRNdQvzAdNZmkY1Qsl4WrVoH2DJBUlJLM4kyeQp4IPqlexCw_aAjt_QCgxlvIEGw_MbL7CVXY2ap2Ln-luepqwsZ7kLNzJpeb15ej1GNLwLUbAHYx9cbqIhezGWivjZvV79vfs_iptZvypJBs2Ppn-VEflHb5D3uB3NtrRxWPTOD7TEud1QgzhhhUnwW_zTZz0v86jaeJmIOSUsf0XjdNiY-a6AIZtfccZ4U3, Captcha ID: 34f4ee59-eb32-4c9e-8ead-845d31d69cce
  end

  def self.decode_recaptcha_v2_invisible
    Hamster.logger.debug "Testing decode_recaptcha_v2() of capsolver.com API when invisible option is true"
    options = {
      pageurl: "https://recaptcha-demo.appspot.com/recaptcha-v2-invisible.php",
      googlekey: '6LcmDCcUAAAAAL5QmnMvDFnfPTP4iCUYRk2MwC0-',
      invisible: 1
    }
    adapter = :capsolver_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout:200, polling:10)
    money = captcha_client.balance

    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
      return nil
    end

    decoded_captcha = captcha_client.decode_recaptcha_v2!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by capsolver_com: 03AKH6MRHct52gEE7m5G2RULKb6P5r9D3Zblc4naRVdQQ-vga0njjuImp3fewJqycmBXzjQ_MV2hwkaujNmC37MN3TACM3PasTO-Jh9EsZcZlQVr8TtBvUgOgS3HTU7TeSyKVv_SO-8inxdbzyddA-JpjxcpSHc6t6VEd7amPmTtIdyO91a1yPQ3RtpJTgARFvFfMMjLpg9Vru1kc6PCtJMzd2VA6h2stqux38pwL0eVc0mz9hC1Q2gyk_eokHPO0C207BTzFdbS3DlK9C-2pdZdggyqC3PntP0XI6q2huR8G2C8NXPlt8EzutZa3elCFcQNHm-nAoQtiC2qQBWAYLPOGY19l14_KBmas9tLaDo_9o9bxZTUeI7R6_5VvbS6eVLiYr-E8YGHLCquyRhK-6QzB1BeFJjsFnEY9COyd7q0_GkJ-C0kikHaOIaOLgvkPNUW25SJF9sQ-TXvPBpl2C2KX63Ysz1ZMcC1rVNIzRFHgI3VnqAP7pfImLOmmRpbaCSnW5OW09T-lhhGOgtqlz3fc5ciQx3NAG4cy82hohNBGgtyNvKXrtkqQnJpZqAtCiUalt8Jl130WEb2Jn-FCYGtE5stzIHoWmRbQ_ODKOI05tPHWJBnMcY1n657W0ogAw_FWpK2-x_Nt-
  end

  def self.decode_recaptcha_v3
    Hamster.logger.debug "Testing decode_recaptcha_v3() of capsolver.com API"
    options = {
      googlekey: '6LcmDCcUAAAAAL5QmnMvDFnfPTP4iCUYRk2MwC0-',
      pageurl:   'https://recaptcha-demo.appspot.com/recaptcha-v3-request-scores.php',
      version: 'v3'
    }
    adapter = :capsolver_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout: 200, polling: 10)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
    end
    decoded_captcha = captcha_client.decode_recaptcha_v3!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by capsolver_com: 03AKH6MREkCJgn8rF7G9czzQnLPT4oBWVUEmOq5j4mC9Q44ao2772LUS8wmFAwu39Io7KDN2PuBytj9Yc4AdxgQ6Ao9GFLVLboqaE7uZTD4ndPIrS_RgJX1MuGwoRJeOdSXLK1aC4oYMoXOrzf8StngBhBsgeZkRo7-6LpQQKPuElOE_LZx_5Bk_yXsyZws4fBkD0REhPNbLrXZgmvBcwEehlVjuJpejHvBEKIn5OfoQn6g5gcAlyFyDvuDFzA2fUe2qfWXe2oR78hE5bc_KfnnKD_iouRr9X0h_oV2ijvq5RrfDYkfGudTqzX8IrJrxmf1fyV6VqmtY2QGf_wPkpSa54y9VhUw4fjyh2EcfF8khvT_OEuBaXz3-P7Bt1mWRIscLxHmy4QPvLQDy559bxHRdau0LxOElHmpMZGijc-vPDXCapV5VdE6x7jASmWXx38Z1bSFsk91KSLi88RLcxwhPyg1sMdYHP2dOewOHxchkDtDoV0Bpltn23jrOkSaEfrQplw_jpH0k4arkTPraRj4YSxv7KzOxv8R4dEEvl2KT4-Itqfqax6z9CPOpEwyO-UmhYwMSlQRpcb28NHTR3oUbhY112Uw5PsPpVg3LuBngj-PsBMMcS-0YCY7k7PurecoTVn7xs2-3RXtDScSiwcqVfxyW1l0yvKAk-n9yQBIuFrV9iZ69lBpjIfHCLSORuLpB1KAFnW0C_nO9zBU5HTaOntcL2hDXbcmJcXQMs4s0pUbjR4WJHrD6PloInoCkJ92XWfDv1iSb4s-sI3PZXOo1gxuwYI_lAfWB2gtwzSH278D3t_amKT2SrJ9I7yiSKHWrMk4BUhpBBnpF7tuqDAifRZ2q5O19Kee1XWhW6g2ZfPMLeE1lZyVvdCxRXj4OP_YLQVTGHRzJixd05wwkpFxKkstcTmpBk_0am52MxUEykzu4aTfxJ1writbMdTtN4vE4VGgriaUHnQYg3AKFCVisXXqtDrPbOSjXvkc9wtPwuoKpI_mnPCrHtn40BpNVJwmrJqJz7KBVyINwWu_JZji-etfssyK5DxCey1_wlFa4qdOVqkjby0ZSTPU526hcNzxs_FDQMFgY0AIJHA3Vv4gJfnzOARUwivbdxXPFNRjhghOtrR0I2MSkgv0pFcl04MLVvolwGhioZV2p-6989gxLSGGLmURh7BZoTpGVnRYEUvmDGQXVMxq-iQRx1-MG5nmNppGI6E-0Slq3MtJmxQio32JUxWkXutyrRcX6ndaFKPxXn8eCzZYat9oLizfrpoNVjtCj0WDwRdHAq0bS5OIGsXoltxthFuwvc93tUna2gjbgPhZjNujjzffbQFaWUZEul1zsJ5t-vJI8xByJ-ryzEMpmwLOGIe7Q42CL1jyvQlU2HP8y5otz2Ri5s6BuHNzOIOW0w2nOXlHdvh4Zion2n9S59ThusEJsDD-2b88HDmggFIpEKF-261LXAkv5m404NJ9fNbFqJ9tvcbwfYiuHI0ZNdYhOZIwk1HhdYATHsHgAMWZmhFus0htHW3M0Ll-QQde1ylhMat2s0iKZ_qE_scdJ4qdE-zKec23v0NnGCr6WnnJ14Rokh7Ndqi9ZDOuh7IliLd1fCxUEVVw-HLXJMUfsQxmkf_V1tKTThxLnlu_jBWz2ZvyjbU3fexPuPFjLjbO8qILhFzJBlxPhB9cjD8pXnWB0S368KAuzv-FMuO_V8zcr9QDAs8M7BbNKVA78F_BuD6VCb1Pl76rA9h2MMgSV8frDCUlPRf0RxMV2tfn6ejDbpAYfhtuu3LjVMF5ejRax-3sb5X4y-8xYurLX0Ih0W4nZJKPRsh3xASznaiuLySx8Mf9ZY1bW-6IX-S1jBY0gZfsDONkGs52zLi66uPXFRBazE5qf8iNGuCk_BnvyqYVqSBbJZ7TuP-3F-rPrwRrdTjS34iHwOE6xVYEj4ryBnZUjUJdOAIUwGd5U_I0ENM1PYdAw3w-222C0y6_1BrkyaDrWfbhMlZT1GaZAEPvxTW8VmYhOEUjF0B9nZUtYBqjIytST23mN0ctg27qdRsTuKnZ9eX43WliyhTfQSTkcymihj5CijuCg6u7hk2nLUW6yFXU19jMq6G68yrY-l7CDn4hR4GGP2WtO0L6E5Oro0NlKvT_PLtLOHYhrvfuyd1HwUBpxDdpGRDTlqAhLhG5vwtcbO569-jIJrMhP3xUNchR2r5NyVySQMaJiOftCvf9IgAHBVKJAKZEzx8odqhzwnN0tG863sC9gJHlPRBTB8qljERjakC5R6tkwQon4cLzUDgYDqpNT_jUxj30qioUtBpoDG1zECGMmZ1Td-WxwGIkUHPGA1eUG4ee3VDJZ8rfEcAapt1pW9UDMoI7ssr-FjOaSFgHC3T3sg63SznKlcz76SxdVaoderN8Y1nQK6-h1Tj4P_wsXNbjWgqNTKSLuJBFln6j1MCNYY0P5noKOx73BbIBKHVp8IaPN1rj-FcqaEihET9hqDE-lIaYYJJu_bV65DcgMwY51Xtjpz64r9xUqkssYnBG6ocONZTfaRq-Fg7CAQxEvVAYOaVExQHZ7r0jqQOJXwV9wvCO_fkfajczn_WjgmNcr0COuX-uMlp89kZB1LHp8o8iNipSDZ0NHzW0hwokn0oxsgIiuohRFeCEJBvnF8KfZyzf4vZn_5rtd9cqBM0BxgzzFtnZGb2sHXT8hAAV8D_FSTDeHL5AMiejZXr3xVVgIb71Jfh_MWj_gNLzkn8ij3Yule3NgWUX83BfSlTyyW16ACirI9knu3Wxd5FQBSJgp3RwbqkPMyS8DIGy4o
  end

  def self.decode_hcaptcha
    Hamster.logger.debug "Testing decode_hcaptcha() of capsolver.com API"
    options = {
      pageurl: "https://hcaptcha.com/",
      sitekey: '00000000-0000-0000-0000-000000000000'
    }
    adapter = :capsolver_com
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout: 200, polling: 10)
    money = captcha_client.balance
    if money < 1
      Hamster.logger.debug "#{adapter} balance < 1"
    end
    decoded_captcha = captcha_client.decode_hcaptcha!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by capsolver_com: W1_eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.3gAFp3Bhc3NrZXnFAeThS0UOW56ed9v7RABMXWZthbDuo4Eucf7uyM1PCihtRfaV4G7jeHGajhGMqNCU_LiKxKNA5VBTd2-4L9xinUw06L-SEuC_3vcVUjyFwzQkJe_McHRX_59en3N-2SDzTY-0aj296mchM4gjDiDwZPsiUusatW8dQ5uy1Jn_XyZnUHTBUTS3YgXqlO93CHsmD7KAQZuBj6-AckTWGiXgHl-1RAbV8y5KxMje5KBFOWrIBeftxta0-LFxdJTlkUuNXXPWmFOKV-rGslvABqKGCvLAoGu7MYfcH8fTknhKcW6iW3vlSPAdmIv8Sxv-k3gbKRTvWpHGZpHndk5Z1tHvrtSXVx2zW1DWTWis5sGG8xc3CkCPltV77qZpHSrlMbft6gJPh6wvaAS-_57SNXoznXg8YZYHbrjv-nGMlnE2Wlfm32u5xbJsQDbM5tyLegRWMY3LeOR-O5mnGnoFJ_3cWbfJvH9QKXZSU9OfMKFibatH5zRRqGl6XzUO061tco65CDN4PepHaLkU62su7N2bCK24rhXUBu71t7I0kzCNLho8GVOC_zmRHrYPU9rAqwFBS1r9pEF3-KvBKH8TkyD8ySCe8-vXZMjgh-SIK755l4ZDLmS-4OTzbeVWMytql4lT0lqxownqp3NpdGVrZXnZJDAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMKNleHDOZDKLWaJwZAClY2RhdGHUAAA.dE7D0T3gPtnn3BhncbST9Cl2Cy4bcXFbEThb7mt4dMo
  end

  def self.turnstile
    
    proxies = PaidProxy.where(is_socks5: 1).to_a rescue []
    
    paid_proxy = proxies.last
    proxy = "socks5:#{paid_proxy.ip}:#{paid_proxy.port}:#{paid_proxy.login}:#{paid_proxy.pwd}"

    Hamster.logger.debug "Testing turnstile() of capsolver.com API"
    # url = "https://peet.ws/turnstile-test/non-interactive.html" # demo
    options = {
      sitekey: "0x4AAAAAAAAjq6WYeRDKmebM",
      pageurl: "https://courtindex.sdcourt.ca.gov/CISPublic/namesearch/",
      proxy: proxy,
      metadata: {
        type: "turnstile",
        action: "login",
        cdata: "0000-1111-2222-3333-example-cdata"
      }
    }
    adapter = :capsolver_com
    
    captcha_client = Hamster::CaptchaAdapter.new(adapter, timeout:200, polling:10)
    Hamster.logger.debug '-'*20, "#{adapter} Balance: #{captcha_client.balance.to_s}"
    decoded_captcha = captcha_client.turnstile!(options)
    Hamster.logger.debug "Token solved by #{adapter}: #{decoded_captcha.text}"
    # Outputs: Token solved by capsolver_com: 0.CED5c6DIjIeNQy9FCzL8DTGMP5N6yejqW5YsO9yf5prUCz50soT8XCMIgLZnsbIwYfo2oLRe9w7qrQqepupfSyVcNMuQhXjP1LnBBXdYwhAOZdi5X5fGUiSUEHBdw8kUOOKJMp4byavKYSzfkz9ISf-9z9QxsVAzVr97nfOM_OHTBYeepZbrUCPSBIj2B5nEJ3jr2VEI29HL9ZdTQGggEXupy0a8tb2zaKhQaXxT1KP1j2jqA-LvAxwOUfwFrQcjeF5RsoFhQ5Orh1OEKFxheESFtNpNTCpRSl-iGdcmyhgB8r64-kEojECmY5wi-FShU9MSzfVtlIGrQdGnFfdqMPOL_p3Sb0DqjXeLCxEP0vw.hdrEqMP5BGFsjyoWOqcPmQ.9826dcceb84bb9403a3b0cd06bd0536695dd535ecb216d0d10a79612ec93e6ad
  end

end




