require 'net/http'
require 'uri'
require 'json'

module Hamster
  module CaptchaAdapter

    class CapsolverClient
      BASE_URLs = { 
        :capsolver_com => 'https://api.capsolver.com/:action'
      }

      attr_accessor :key, :timeout, :polling, :adapter, :app_id

      # Create a Capsolver API client.
      #
      # @param [String] Captcha adapter.
      # @param [Hash]   options  Options hash.
      # @option options [Integer] :timeout (60) Seconds before giving up of a
      #                                         captcha being solved.
      # @option options [Integer] :polling  (5) Seconds before check_answer again
      #
      # @return [CaptchaAdapter::CapsolverClient] A Client instance.
      #
      def initialize(adapter = :capsolver_com, options = {})
        captcha_tokens = Storage.new.captcha_keys
        if captcha_tokens.keys.include?(adapter.to_s)
          key = captcha_tokens[adapter]
        end
        if key.nil?
          raise ArgumentError, "The captcha key for the adapter :#{adapter.to_s} not provided in config.yml. Add captcha key in config.yml. For example 
              captcha_keys:
                capsolver_com: CAI-1CD66A0269F9B9B69B4EE81E4C6DXXXX"

        end
        if key.length != 36
          raise ArgumentError, "Wrong key to token or wrong token to captcha solver.
                The token must be 32 characters long or your config doesn't have keys for captcha solver.
                Please, check your config file."
        end
        
        self.adapter = adapter
        self.key     = key
        self.app_id  = captcha_tokens[adapter.to_s + "_app_id"]
        self.timeout = options[:timeout] || 60
        self.polling = options[:polling] || 5
      end


      # Get balance from your account.
      #
      # @return [Float] Balance in USD.
      #
      def balance
        request('getBalance')['balance'].to_f
      end


      # Decode the text from an image (i.e. solve a captcha).
      #
      # @param [Hash] options Options hash. Check docs for the method decode!.
      #
      # @return [CaptchaAdapter::Captcha] The captcha (with solution) or an empty
      #                               captcha instance if something goes wrong.
      def decode_image(options = {})
        decode_image!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end
      alias :decode :decode_image

      # Solve ImageToTextTask
      # Implemented from https://docs.capsolver.com/guide/recognition/ImageToTextTask.html
      # @param [Hash] options Options hash.
      # @option options [String] :body      The binary image base64 encoded.
      # @option options [String] :url       image url
      # @option options [String] :module    Optional "common" or "queueit"
      # @return Response body of the HTTP request.
      def decode_image!(options = {})
        if options[:body].nil? && options[:url].nil?
          raise CaptchaAdapter::ArgumentError, 'Param options[:body] is not defined!'
        end
        payload = {task: {type: "ImageToTextTask"}}
        payload[:task][:module] = "common" if options[:module].nil?

        unless options[:body].nil?
          payload[:task][:body] = options[:body]
        else 
          img = open(options[:url])
          img_body = Base64.encode64(img.read)
          payload[:task][:body] = img_body
        end
        decoded_captcha = CaptchaAdapter::Captcha.new
        response = request('createTask', payload)
        decoded_captcha.id = response["taskId"]
        decoded_captcha.api_response = response
        decoded_captcha.text = response["solution"]["text"]
        
        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_image',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end

      alias :decode! :decode_image!


      # Solve HCaptchaClassification
      # Implemented from https://docs.capsolver.com/guide/recognition/HCaptchaClassification.html
      # @param [Hash] options Options hash.
      # @option options [String] :question, required
      # @option options [Array of string] :queries, required
      # @return Response body of the HTTP request.
      def decode_hcaptcha_classification(options = {})
        if options[:question].nil? || options[:queries].nil? || options[:queries].empty?
          raise CaptchaAdapter::ArgumentError, 'Param options[:question] or options[:queries] undefined, or options[:queries] empty!'
        end
        payload = {task: {type: "HCaptchaClassification"}}
        payload[:task] = payload[:task].merge(options)

        decoded_captcha = CaptchaAdapter::Captcha.new
        response = request('createTask', payload)
        decoded_captcha.id = response["taskId"]
        decoded_captcha.api_response = response
        decoded_captcha.text = response["solution"].to_s

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_hcaptcha_classification',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
        CaptchaAdapter::CaptchaStatistics.insert(data)
        
        decoded_captcha
      end

      # Solve FunCaptchaClassification
      # Implemented from https://docs.capsolver.com/guide/recognition/FunCaptchaClassification.html
      # @param [Hash] options Options hash.
      # @option options [String] :question, required
      # You can find question list on https://docs.capsolver.com/guide/recognition/FunCaptchaClassification.html
      # @option options [Array of string] :images, required
      # @return Response body of the HTTP request.
      def decode_fun_captcha_classification(options = {})
        if options[:question].nil? || options[:images].nil? || options[:images].empty?
          raise CaptchaAdapter::ArgumentError, 'Param options[:question] or options[:images] undefined!'
        end
        payload = {task: {type: "FunCaptchaClassification"}}
        payload[:task] = payload[:task].merge(options)
        
        response = request('createTask', payload)
        decoded_captcha.id = response["taskId"]
        decoded_captcha.api_response = response
        decoded_captcha.text = response["solution"].to_s

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_fun_captcha_classification',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end


      # Solve ReCaptchaV2Classification
      # Implemented from https://docs.capsolver.com/guide/recognition/ReCaptchaClassification.html
      # @param [Hash] options Options hash.
      # @option options [string] :image  - base64 image string, Required
      # @option options [String] :question - Required
      # @return Response body of the HTTP request.
      def decode_re_captcha_v2_classification(options = {})
        if options[:image].nil? || options[:question].nil?
          raise CaptchaAdapter::ArgumentError, 'Param options[:image] or options[:question] undefined!'
        end
        payload = {task: {type: "ReCaptchaV2Classification"}}
        payload[:task] = payload[:task].merge(options)

        response = request('createTask', payload)
        decoded_captcha.id = response["taskId"]
        decoded_captcha.api_response = response
        decoded_captcha.text = response["solution"].to_s

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_re_captcha_v2_classification',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end

      # Solve AwsWafClassification
      # Implemented from https://docs.capsolver.com/guide/recognition/AwsWafClassification.html
      # @param [Hash] options Options hash.
      # @option options [Array of string] :images  - array of base64 string, Required
      # @option options [String] :question - Required
      # @return Response body of the HTTP request.
      def decode_aws_waf_classification(options = {})
        if options[:images].nil? || options[:question].nil? || options[:images].empty?
          raise CaptchaAdapter::ArgumentError, 'Param options[:images] or options[:question] unefined!'
        end
        payload = {task: {type: "AwsWafClassification"}}
        payload[:task] = payload[:task].merge(options)
        
        response = request('createTask', payload)
        decoded_captcha.id = response["taskId"]
        decoded_captcha.api_response = response
        decoded_captcha.text = response["solution"].to_s

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_aws_waf_classification',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end


      #
      # Solve reCAPTCHA v2.
      #
      # @param [Hash] options Options hash. Check docs for the method decode!.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def decode_recaptcha_v2(options = {})
        decode_recaptcha_v2!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end

      #
      # Solve reCAPTCHA v2.
      # https://docs.capsolver.com/guide/captcha/ReCaptchaV2.html
      # @param [Hash] options Options hash.
      # @option options [String]  :websiteKey The open key of the site in which recaptcha is installed.
      # @option options [String]  :websiteURL The URL of the page where the recaptcha is encountered.
      # @return [CaptchaAdapter::Captcha] The captcha object.
      # @return Ex: <Hamster::CaptchaAdapter::Captcha:0x000055987da890b0 @id="34fecf1a-877f-462b-a4ac-8c9e83546b40", @api_response={"errorId"=>0, "taskId"=>"34fecf1a-877f-462b-a4ac-8c9e83546b40", "status"=>"ready", "solution"=>{"gRecaptchaResponse"=>"03AKH6MRHguRA5wfsXSery9FivDrrNAN0trC6gzI7N_D1bVeSw3Z59HQ9lD_uZ9ljuE5KIYHJFHrXLHpmnaRLGDOmgXcicFrsDOi2P1xW0RMFHexasG_0jaZYfh2JxsNWhanX9PBc1wIc5vtTAyjN2DTUKBvL4ItTEZSifOQvGQSq9hfNRXChscviS1O4wLOOupWm9jK4bPFMTSil8KvLEis3YV0Crrvhyb0iwEJIF9bWvWM-ZH0ToprDxXhpm1A-yPwNzngk0CawP_kZoUAXZF3RmXwuEP3aWJCzZIV7N6BboxpdmOR-9Ado9PmJSe7Ezxe204a0UosuWAIlqafwWYNchkzAvrjUDQbvUB6AYtoDZqgEBImhOjWYKIXADm_ZZolt9dNtPK8QULdEvHI05zK9qQkvMCUnVS9TGwjonbJagVVYpMh43Y7gJuHjS5fSBVnUoDV4uwCMKIqHrA0doJkPjv42LA6acZ7nPZ5ilvEhed8RApwfZtTVtwaZ83KmUMjSR2Fsq4RxbAo83RYggZdDuufbkAE3Jl_rNKA-vsI8p5vNmjqgrDBy-LfeiJ22JyQfZi1zQG96rLo-OmgriFkaqCeCam4SSQs47g0wEl0jJllduTcKqqm9jWNzBRmTCyYIpSu5NUD66", "userAgent"=>"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"}}, @text="03AKH6MRHguRA5wfsXSery9FivDrrNAN0trC6gzI7N_D1bVeSw3Z59HQ9lD_uZ9ljuE5KIYHJFHrXLHpmnaRLGDOmgXcicFrsDOi2P1xW0RMFHexasG_0jaZYfh2JxsNWhanX9PBc1wIc5vtTAyjN2DTUKBvL4ItTEZSifOQvGQSq9hfNRXChscviS1O4wLOOupWm9jK4bPFMTSil8KvLEis3YV0Crrvhyb0iwEJIF9bWvWM-ZH0ToprDxXhpm1A-yPwNzngk0CawP_kZoUAXZF3RmXwuEP3aWJCzZIV7N6BboxpdmOR-9Ado9PmJSe7Ezxe204a0UosuWAIlqafwWYNchkzAvrjUDQbvUB6AYtoDZqgEBImhOjWYKIXADm_ZZolt9dNtPK8QULdEvHI05zK9qQkvMCUnVS9TGwjonbJagVVYpMh43Y7gJuHjS5fSBVnUoDV4uwCMKIqHrA0doJkPjv42LA6acZ7nPZ5ilvEhed8RApwfZtTVtwaZ83KmUMjSR2Fsq4RxbAo83RYggZdDuufbkAE3Jl_rNKA-vsI8p5vNmjqgrDBy-LfeiJ22JyQfZi1zQG96rLo-OmgriFkaqCeCam4SSQs47g0wEl0jJllduTcKqqm9jWNzBRmTCyYIpSu5NUD66">
      #
      def decode_recaptcha_v2!(options = {})
        
        options[:websiteKey] = options[:websiteKey] || options[:googlekey]  
        options[:websiteURL] = options[:websiteURL] || options[:pageurl]
        options.delete(:googlekey)
        options.delete(:pageurl)

        started_at = Time.now
        if options[:websiteKey].nil? || options[:websiteURL].nil?
          raise CaptchaAdapter::ArgumentError, 'Param options[:websiteKey] or options[:websiteURL] are unefined!'
        end
        # payload = {task: {type: "ReCaptchaV2Task"}}
        if !options[:proxy].nil? && !options[:proxy].emepty?
          payload = {task: {type: "ReCaptchaV2Task"}}
        else
          payload = {task: {type: "ReCaptchaV2TaskProxyLess"}}
        end
        payload[:task] = payload[:task].merge(options)
        response = request('createTask', payload)

        if response["taskId"].nil?
          raise "errorCode: #{response["errorCode"]} errorDescription: #{response["errorDescription"]}"
        end
        
        decoded_captcha = captcha(response["taskId"])
        while decoded_captcha.api_response["status"] != "ready"
          
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(response["taskId"])
          
          if decoded_captcha.api_response["status"] != "ready"
            raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
          end
          if decoded_captcha.api_response["status"] == "failed"
            raise CaptchaAdapter::CaptchaUnsolvable
          end
        end

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_recaptcha_v2',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:websiteURL] if options.has_key?(:websiteURL)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end

      #
      # Solve reCAPTCHA v3.
      #
      # @param [Hash] options Options hash. Check docs for the method decode!.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def decode_recaptcha_v3(options = {})
        decode_recaptcha_v3!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end

      #
      # Solve reCAPTCHA v3.
      # https://docs.capsolver.com/guide/captcha/ReCaptchaV3.html
      # @param [Hash] options Options hash.
      # @option options [String]  :websiteKey The open key of the site in which recaptcha is installed.
      # @option options [String]  :websiteURL The URL of the page where the recaptcha is encountered.
      # @option options [String]  :pageAction The action paramenter present on the page that uses recaptcha.
      # @option options [String]  :minScore The minimum score necessary to pass the challenge.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def decode_recaptcha_v3!(options = {})
        
        options[:websiteKey] ||= options[:googlekey]  
        options[:websiteURL] ||= options[:pageurl]
        options[:pageAction] ||= options[:action]
        options[:minScore] ||= options[:min_score]
        options.delete(:googlekey)
        options.delete(:pageurl)
        options.delete(:action)
        options.delete(:min_score)
        
        started_at = Time.now
        if options[:websiteKey].nil? || options[:websiteURL].nil?
          raise CaptchaAdapter::ArgumentError, 'Param options[:websiteKey] or options[:websiteURL] are unefined!'
        end
        # payload = {task: {type: "ReCaptchaV2Task"}}
        if !options[:proxy].nil? && !options[:proxy].emepty?
          payload = {task: {type: "ReCaptchaV3Task"}}
        else
          payload = {task: {type: "ReCaptchaV3TaskProxyLess"}}
        end
        payload[:task] = payload[:task].merge(options)
        response = request('createTask', payload)

        if response["taskId"].nil?
          raise "errorCode: #{response["errorCode"]} errorDescription: #{response["errorDescription"]}"
        end
        
        decoded_captcha = captcha(response["taskId"])
        while decoded_captcha.api_response["status"] != "ready"
          
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(response["taskId"])
          
          if decoded_captcha.api_response["status"] != "ready"
            raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
          end
          if decoded_captcha.api_response["status"] == "failed"
            raise CaptchaAdapter::CaptchaUnsolvable
          end
        end

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_recaptcha_v3',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:websiteURL] if options.has_key?(:websiteURL)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end

      #
      # Solve hCaptcha.
      #
      # @param [Hash] options Options hash. Check docs for the method decode_hcaptcha!.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def decode_hcaptcha(options = {})
        decode_hcaptcha!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end

      #
      # Solve hCaptcha.
      # https://docs.capsolver.com/guide/captcha/HCaptcha.html
      # @param [Hash] options Options hash.
      # @option options [String]  :websiteKey The  key of the site in which hCaptcha is installed.
      # @option options [String]  :websiteURL The URL of the page where the recaptcha is encountered.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def decode_hcaptcha!(options = {})
        
        options[:websiteKey] ||= options[:sitekey]  
        options[:websiteURL] ||= options[:pageurl]
        options.delete(:sitekey)
        options.delete(:pageurl)
        
        started_at = Time.now
        if options[:websiteKey].nil? || options[:websiteURL].nil?
          raise CaptchaAdapter::ArgumentError, 'Param options[:websiteKey] or options[:websiteURL] are unefined!'
        end
        
        if !options[:proxy].nil? && !options[:proxy].emepty?
          payload = {task: {type: "HCaptchaTask"}}
        else
          payload = {task: {type: "HCaptchaTaskProxyLess"}}
        end
        payload[:task] = payload[:task].merge(options)
        response = request('createTask', payload)

        if response["taskId"].nil?
          raise "errorCode: #{response["errorCode"]} errorDescription: #{response["errorDescription"]}"
        end
        
        decoded_captcha = captcha(response["taskId"])
        while decoded_captcha.api_response["status"] != "ready"
          
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(response["taskId"])
          
          if decoded_captcha.api_response["status"] != "ready"
            raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
          end
          if decoded_captcha.api_response["status"] == "failed"
            raise CaptchaAdapter::CaptchaUnsolvable
          end
        end

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_hcaptcha',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:websiteURL] if options.has_key?(:websiteURL)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end

      #
      # Solve Cloudflare Turnstile.
      #
      # @param [Hash] options Options hash. Check docs for the method decode!.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def turnstile(options = {})
        turnstile!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end 

      # Solver for Cloudflare Turnstile
      # https://docs.capsolver.com/guide/antibots/cloudflare_turnstile.html
      # @param [Hash] options Options hash.
      # @option options [String]  :websiteKey The  key of the site in which hCaptcha is installed.
      # @option options [String]  :websiteURL The URL of the page where the recaptcha is encountered.
      # @option options [String]  :metadata, required extra data, https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/
      # @option options [String]  :proxy Learn using proxies. Read original API Doc: https://docs.capsolver.com/guide/api-how-to-use-proxy.html
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def turnstile!(options = {})
        
        options[:websiteKey] ||= options[:sitekey]  
        options[:websiteURL] ||= options[:pageurl]
        options.delete(:googlekey)
        options.delete(:pageurl)
        
        options[:metadata][:type] = "turnstile"

        started_at = Time.now
        if options[:websiteKey].nil? || options[:websiteURL].nil? || options[:proxy].nil?
          raise CaptchaAdapter::ArgumentError, 'Param options[:websiteKey], options[:websiteURL] or options[:proxy] are unefined!'
        end

        payload = {task: {type: "AntiCloudflareTask"}}
      
        payload[:task] = payload[:task].merge(options)
        response = request('createTask', payload)

        if response["taskId"].nil?
          raise "errorCode: #{response["errorCode"]} errorDescription: #{response["errorDescription"]}"
        end
        
        decoded_captcha = captcha(response["taskId"])
        while decoded_captcha.api_response["status"] != "ready"
          
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(response["taskId"])
          
          if decoded_captcha.api_response["status"] != "ready"
            raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
          end
          if decoded_captcha.api_response["status"] == "failed"
            raise CaptchaAdapter::CaptchaUnsolvable
          end
        end

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'turnstile',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:websiteURL] if options.has_key?(:websiteURL)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end
      #
      # Solve Cloudflare TChallenge (5s)
      #
      # @param [Hash] options Options hash. Check docs for the method decode!.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def challenge_5s(options = {})
        challenge_5s!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end 

      # Solver for Cloudflare Challenge (5s)
      # https://docs.capsolver.com/guide/antibots/cloudflare_challenge.html
      # @param [Hash] options Options hash.
      # @option options [String]  :websiteKey The  key of the site in which hCaptcha is installed.
      # @option options [String]  :websiteURL The URL of the page where the recaptcha is encountered.
      # @option options [String]  :metadata, required extra data, https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/
      # @option options [String]  :proxy Learn using proxies. Read original API Doc: https://docs.capsolver.com/guide/api-how-to-use-proxy.html
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def challenge_5s!(options = {})
        
        options[:websiteKey] ||= options[:sitekey]  
        options[:websiteURL] ||= options[:pageurl]
        options.delete(:googlekey)
        options.delete(:pageurl)
        
        options = options.merge({metadata: {type: "challenge"}}) 

        started_at = Time.now
        if options[:websiteKey].nil? || options[:websiteURL].nil? || options[:proxy].nil?
          raise CaptchaAdapter::ArgumentError, 'Param options[:websiteKey], options[:websiteURL] or options[:proxy] are unefined!'
        end

        payload = {task: {type: "AntiCloudflareTask"}}
      
        payload[:task] = payload[:task].merge(options)
        response = request('createTask', payload)

        if response["taskId"].nil?
          raise "errorCode: #{response["errorCode"]} errorDescription: #{response["errorDescription"]}"
        end
        
        decoded_captcha = captcha(response["taskId"])
        while decoded_captcha.api_response["status"] != "ready"
          
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(response["taskId"])
          
          if decoded_captcha.api_response["status"] != "ready"
            raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
          end
          if decoded_captcha.api_response["status"] == "failed"
            raise CaptchaAdapter::CaptchaUnsolvable
          end
        end

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'challenge_5s',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:websiteURL] if options.has_key?(:websiteURL)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end

      def datadome(options = {})
        datadome!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end 

      # Solver for Datadome
      # https://docs.capsolver.com/guide/antibots/datadome.html
      # @param [Hash] options Options hash.
      # @option options [String]  :captchaUrl if the url contains t=bv that means that your ip must be banned, t should be t=fe
      # @option options [String]  :websiteURL The address of the target page.
      # @option options [String]  :proxy Learn using proxies. Read original API Doc: https://docs.capsolver.com/guide/api-how-to-use-proxy.html
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def datadome!(options = {})
        
        options[:websiteURL] ||= options[:pageurl]
        options.delete(:googlekey)
        options.delete(:pageurl)
        
        started_at = Time.now
        if options[:captchaUrl].nil? || options[:websiteURL].nil? || options[:proxy].nil?
          raise CaptchaAdapter::ArgumentError, 'Param options[:captchaUrl], options[:websiteURL] or options[:proxy] are unefined!'
        end

        payload = {task: {type: "DatadomeSliderTask"}}
      
        payload[:task] = payload[:task].merge(options)
        response = request('createTask', payload)

        if response["taskId"].nil?
          raise "errorCode: #{response["errorCode"]} errorDescription: #{response["errorDescription"]}"
        end
        
        decoded_captcha = captcha(response["taskId"])
        while decoded_captcha.api_response["status"] != "ready"
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(response["taskId"])
          
          if decoded_captcha.api_response["status"] != "ready"
            raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
          end
          if decoded_captcha.api_response["status"] == "failed"
            raise CaptchaAdapter::CaptchaUnsolvable
          end
        end

        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'datadome',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:websiteURL] if options.has_key?(:websiteURL)
        CaptchaAdapter::CaptchaStatistics.insert(data)

        decoded_captcha
      end

      # Perform an HTTP request to the Captcha API.
      #
      # @param [String] action  API method name.
      # @param [Hash]   payload Data to be sent through the HTTP request.
      # 
      #
      def request(action, payload = {})
        response = nil
        uri = URI(BASE_URLs[adapter].gsub(':action', action))
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          
          request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
          request.body = payload.merge({clientKey: key}).to_json
          response = http.request request # Net::HTTPResponse object
        end
        JSON.parse(response.body)
      end
      
      def captcha(task_id)
        response = request('getTaskResult', {taskId: task_id})
        
        decoded_captcha = CaptchaAdapter::Captcha.new(id: task_id)
        decoded_captcha.api_response = response
        if response["status"] == "ready"
          decoded_captcha.text = response["solution"]["gRecaptchaResponse"]    # When HCaptcha, ReCaptchaV2, ReCaptchaV3Task
          decoded_captcha.text ||= response["solution"]["token"]               # When FunCaptcha, MtCaptcha, Cloudflare(Turnstile, Challenge)
          decoded_captcha.text ||= response["solution"].to_s
        end
        decoded_captcha
      end

      def validate_response(response)
        if (error = CaptchaAdapter::RESPONSE_ERRORS[response])
          raise(error)
        elsif response.to_s.empty? || response.match(/\AERROR\_/)
          raise(CaptchaAdapter::Error, response)
        end
      end
    end
  end
end