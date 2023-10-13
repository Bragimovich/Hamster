
module Hamster
  module CaptchaAdapter
    # CaptchaAdapter::Client is a client that communicates with the captcha APIs
    # Available now : 2captcha.com, captchas.io, azcaptcha.com, 

    class Client
      BASE_URLs = { 
        :two_captcha_com => 'http://2captcha.com/:action.php',
        :captchas_io => 'https://api.captchas.io/:action.php',
        :azcaptcha_com => 'https://azcaptcha.com/:action.php',
      }

      attr_accessor :key, :timeout, :polling, :adapter, :keeper

      # Create a TwoCaptcha API client.
      #
      # @param [String] Captcha adapter.
      # @param [Hash]   options  Options hash.
      # @option options [Integer] :timeout (60) Seconds before giving up of a
      #                                         captcha being solved.
      # @option options [Integer] :polling  (5) Seconds before check_answer again
      #
      # @return [CaptchaAdapter::Client] A Client instance.
      #
      def initialize(adapter = :two_captcha_com, options = {})
        two_captcha_tokens = Storage.new.captcha_keys
        return unless two_captcha_tokens
        
        if two_captcha_tokens.keys.include?(adapter.to_s)
          key = two_captcha_tokens[adapter]
        end
        if key.nil?
          raise ArgumentError, "The captcha key for the adapter :#{adapter.to_s} not provided in config.yml. Add captcha key in config.yml. For example 
              captcha_keys:
                two_captcha_com: 3faa98b3c9e2254ebe22a3eb7cacxxxx
                captchas_io: 53051exx-63ed01df339bxx.742204xxx
                azcaptcha_com: 92whfxnyqp8xmttr3vh6dzljxxxxxxxx"

        end
        if key.length != 32
          raise ArgumentError, "Wrong key to token or wrong token to captcha solver.
                The token must be 32 characters long or your config doesn't have keys for captcha solver.
                Please, check your config file."
        end
        
        self.adapter = adapter
        self.key     = key
        self.timeout = options[:timeout] || 60
        self.polling = options[:polling] || 5
        self.keeper = CaptchaAdapter::CaptchaStatistics.new
      end

      # Decode the text from an image (i.e. solve a captcha).
      #
      # @param [Hash] options Options hash. Check docs for the method decode!.
      #
      # @return [CaptchaAdapter::Captcha] The captcha (with solution) or an empty
      #                               captcha instance if something goes wrong.
      #
      def decode_image(options = {})
        decode_image!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end
      alias :decode :decode_image

      # Decode the text from an image (i.e. solve a captcha).
      #
      # @param [Hash] options Options hash.
      # @option options [String]  :url   URL of the image to be decoded.
      # @option options [String]  :path  File path of the image to be decoded.
      # @option options [File]    :file  File instance with image to be decoded.
      # @option options [String]  :raw   Binary content of the image to be
      #                                  decoded.
      # @option options [String]  :raw64 Binary content encoded in base64 of the
      #                                  image to be decoded.
      # @option options [Integer] :phrase         (0) ex: https://2captcha.com/setting
      # @option options [Integer] :regsense       (0) ex: https://2captcha.com/setting
      # @option options [Integer] :numeric        (0) ex: https://2captcha.com/setting
      # @option options [Integer] :calc           (0) ex: https://2captcha.com/setting
      # @option options [Integer] :min_len        (0) ex: https://2captcha.com/setting
      # @option options [Integer] :max_len        (0) ex: https://2captcha.com/setting
      # @option options [Integer] :language       (0) ex: https://2captcha.com/setting
      # @option options [Integer] :header_acao    (0) ex: https://2captcha.com/setting
      # @option options [Integer] :id_constructor (0) 23 if new reCAPTCHA.
      # @option options [Integer] :coordinatescaptcha (0) 1 if clickable captcha.
      #
      # @return [CaptchaAdapter::Captcha] The captcha (with solution) if an error is
      #                               not raised.
      #
      def decode_image!(options = {})
        started_at = Time.now

        raw64 = load_captcha(options)
        raise(CaptchaAdapter::InvalidCaptcha) if raw64.to_s.empty?

        decoded_captcha = upload(options.merge(raw64: raw64))

        # pool untill the answer is ready
        while decoded_captcha.text.to_s.empty?
          sleep(polling)
          decoded_captcha = captcha(decoded_captcha.id)
          raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
        end
        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_image',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:url] if options.has_key?(:url)
        CaptchaAdapter::CaptchaStatistics.insert(data)
        decoded_captcha
      end
      alias :decode! :decode_image!

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
      #
      # @param [Hash] options Options hash.
      # @option options [String]  :googlekey The open key of the site in which recaptcha is installed.
      # @option options [String]  :pageurl The URL of the page where the recaptcha is encountered.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def decode_recaptcha_v2!(options = {})
        started_at = Time.now

        raise(CaptchaAdapter::GoogleKey) if options[:googlekey].empty?

        upload_options = { method: 'userrecaptcha' }.merge(options)
        decoded_captcha = upload(upload_options)

        # pool untill the answer is ready
        while decoded_captcha.text.to_s.empty?
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(decoded_captcha.id)
          break unless decoded_captcha.text.to_s.empty?
          raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
        end
        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_recaptcha_v2',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
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
      #
      # @param [Hash] options Options hash.
      # @option options [String]  :googlekey The open key of the site in which recaptcha is installed.
      # @option options [String]  :pageurl The URL of the page where the recaptcha is encountered.
      # @option options [String]  :action The action paramenter present on the page that uses recaptcha.
      # @option options [String]  :min_score The minimum score necessary to pass the challenge.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def decode_recaptcha_v3!(options = {})
        started_at = Time.now

        raise(CaptchaAdapter::GoogleKey) if options[:googlekey].empty?

        upload_options = {
          method:  'userrecaptcha',
          version: 'v3',
        }.merge(options)
        decoded_captcha = upload(upload_options)

        # pool untill the answer is ready
        while decoded_captcha.text.to_s.empty?
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(decoded_captcha.id)
          break unless decoded_captcha.text.to_s.empty?
          raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
        end
        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_recaptcha_v3',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
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
      # Help: https://2captcha.com/2captcha-api#solving_hcaptcha
      # @param [Hash] options Options hash.
      # @option options [String]  :sitekey The  key of the site in which hCaptcha is installed.
      # @option options [String]  :pageurl The URL of the page where the recaptcha is encountered.
      #
      # @return [CaptchaAdapter::Captcha] The solution of the given captcha.
      #
      def decode_hcaptcha!(options = {})
        started_at = Time.now

        raise(CaptchaAdapter::SiteKey) if options[:sitekey].empty?

        upload_options = { method: 'hcaptcha' }.merge(options)
        decoded_captcha = upload(upload_options)

        # pool untill the answer is ready
        while decoded_captcha.text.to_s.empty?
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(decoded_captcha.id)
          break unless decoded_captcha.text.to_s.empty?
          raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
        end
        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'decode_hcaptcha',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
        CaptchaAdapter::CaptchaStatistics.insert(data)
        decoded_captcha
      end


      def turnstile(options = {})
        turnstile!(options)
      rescue CaptchaAdapter::Error => ex
        CaptchaAdapter::Captcha.new
      end      
      # Solver for Cloudflare Turnstile
      # 
      # @option options [String]  :sitekey The  key of the site in which hCaptcha is installed.
      # @option options [String]  :pageurl The URL of the page where the recaptcha is encountered.
      # Ex: options = { sitekey: '0x4AAAAAAAChNiVJM_WtShFf', url: 'https://ace.fusionist.io'}
      # @return Hamster::CaptchaAdapter::Captcha object
      #  ex:) #<Hamster::CaptchaAdapter::Captcha:0x00005620fc376ba8 @id="73118782223", @api_response="OK|0.kTO49HnhSER8IxKKtZrv9rc5qDRfAaW3G9edUTLIzwXbCMgRzFqwKU-Ew66qEg8OHAj0E5ipN1wD0xfrywRKGCa070B0jEpj4gldpUJX9VcwTBEQY-rvMchajV3fnm2bpvtU7IkxpWbrQiWEvtFkBne1MmSJ7LBSSm33-gsibbxyn_IA_9YI9HLwDCV74CoQ_JPNBvcMiI20ut-SyjhOJxCoaqr0Auv2ZVHhrw5NphXS2zRiZvC4ayNNhuw9rsgM41NszvmB46xRohbS2BmNDWLS4ch9C2TGjRxfkOOa-pORor_cvWvKhAlsJbTyJfLMTeoJRuJy-L4XYI4-SJkelw.hGxxKdMWQe5jHwwryMB7gg.b28429537788d288ac1094c0a614fef157cd181f8082f4e16f2e410b0efa932c", @text="0.kTO49HnhSER8IxKKtZrv9rc5qDRfAaW3G9edUTLIzwXbCMgRzFqwKU-Ew66qEg8OHAj0E5ipN1wD0xfrywRKGCa070B0jEpj4gldpUJX9VcwTBEQY-rvMchajV3fnm2bpvtU7IkxpWbrQiWEvtFkBne1MmSJ7LBSSm33-gsibbxyn_IA_9YI9HLwDCV74CoQ_JPNBvcMiI20ut-SyjhOJxCoaqr0Auv2ZVHhrw5NphXS2zRiZvC4ayNNhuw9rsgM41NszvmB46xRohbS2BmNDWLS4ch9C2TGjRxfkOOa-pORor_cvWvKhAlsJbTyJfLMTeoJRuJy-L4XYI4-SJkelw.hGxxKdMWQe5jHwwryMB7gg.b28429537788d288ac1094c0a614fef157cd181f8082f4e16f2e410b0efa932c">
      # 
      def turnstile!(options = {})
        started_at = Time.now

        raise(CaptchaAdapter::SiteKey) if options[:sitekey].empty?

        decoded_captcha = request('in', :get, method: :turnstile, sitekey: options[:sitekey], pageurl: options[:pageurl])
        captcha_id = decoded_captcha.split('|', 2)[1].strip rescue nil
        raise(CaptchaAdapter::CaptchaUnsolvable) if captcha_id.nil?
        # pool untill the answer is ready
        while true
          sleep([polling, 10].max) # sleep at least 10 seconds
          decoded_captcha = captcha(captcha_id)
          captcha_id = decoded_captcha.id
          break if decoded_captcha.api_response != "CAPCHA_NOT_READY"
          raise CaptchaAdapter::Timeout if (Time.now - started_at) > timeout
        end
        data = {
          adapter: adapter,
          project_number: Hamster.project_number,
          solution: 'turnstile',
          is_solved: true,
          payload: options.to_json,
          response: decoded_captcha.to_json,
        }
        data[:website_url] = options[:pageurl] if options.has_key?(:pageurl)
        decoded_captcha
      end

      # Upload a captcha to 2Captcha.
      #
      # This method will not return the solution. It helps on separating concerns.
      #
      # @return [CaptchaAdapter::Captcha] The captcha object (not solved yet).
      #
      def upload(options = {})
        args = {}
        args[:body]   = options[:raw64] if options[:raw64]
        args[:method] = options[:method] || 'base64'
        args.merge!(options)
        response = request('in', :multipart, args)

        unless response.match(/\AOK\|/)
          raise(CaptchaAdapter::Error, 'Unexpected API Response')
        end

        CaptchaAdapter::Captcha.new(
          id: response.split('|', 2)[1],
          api_response: response
        )
      end

      # Retrieve information from an uploaded captcha.
      #
      # @param [Integer] captcha_id Numeric ID of the captcha.
      #
      # @return [CaptchaAdapter::Captcha] The captcha object.
      #
      def captcha(captcha_id)
        response = request('res', :get, action: 'get', id: captcha_id)

        decoded_captcha = CaptchaAdapter::Captcha.new(id: captcha_id)
        decoded_captcha.api_response = response

        if response.match(/\AOK\|/)
          decoded_captcha.text = response.split('|', 2)[1]
        end

        decoded_captcha
      end

      # Report incorrectly solved captcha for refund.
      #
      # @param [Integer] id Numeric ID of the captcha.
      # @param [Integer] action 'reportbad' (default) or 'reportgood'.
      #
      # @return [Boolean] true if correctly reported
      #
      def report!(captcha_id, action = 'reportbad')
        response = request('res', :get, action: action, id: captcha_id)
        response == 'OK_REPORT_RECORDED'
      end

      # Get balance from your account.
      #
      # @return [Float] Balance in USD.
      #
      def balance
        request('res', :get, action: 'getbalance').to_f
      end

      # Get statistics from your account.
      #
      # @param [Date] date Date when the statistics were collected.
      #
      # @return [String] Statistics from date in an XML string.
      #
      def stats(date)
        request('res', :get, action: 'getstats', date: date.strftime('%Y-%m-%d'))
      end

      # Get current load from 2Captcha.
      #
      # @return [String] Load in an XML string.
      #
      def load
        request('load', :get)
      end
      
      private

      # Load a captcha raw content encoded in base64 from options.
      #
      # @param [Hash] options Options hash.
      # @option options [String]  :url   URL of the image to be decoded.
      # @option options [String]  :path  File path of the image to be decoded.
      # @option options [File]    :file  File instance with image to be decoded.
      # @option options [String]  :raw   Binary content of the image to bedecoded.
      # @option options [String]  :raw64 Binary content encoded in base64 of the
      #                                  image to be decoded.
      #
      # @return [String] The binary image base64 encoded.
      #
      def load_captcha(options)
        if options[:raw64]
          options[:raw64]
        elsif options[:raw]
          Base64.encode64(options[:raw])
        elsif options[:file]
          Base64.encode64(options[:file].read)
        elsif options[:path]
          Base64.encode64(File.open(options[:path], 'rb').read)
        elsif options[:url]
          Base64.encode64(CaptchaAdapter::HTTP.open_url(options[:url]))
        else
          raise CaptchaAdapter::ArgumentError, 'Illegal image format'
        end
      rescue
        raise CaptchaAdapter::InvalidCaptcha
      end

      # Perform an HTTP request to the 2Captcha API.
      #
      # @param [String] action  API method name.
      # @param [Symbol] method  HTTP method (:get, :post, :multipart).
      # @param [Hash]   payload Data to be sent through the HTTP request.
      #
      # @return [String] Response from the Captcha API.
      #
      def request(action, method = :get, payload = {})

        payload[:id] = payload[:id].strip unless payload[:id].nil?
        res = CaptchaAdapter::HTTP.request(
          url: BASE_URLs[adapter].gsub(':action', action),
          timeout: timeout,
          method: method,
          payload: payload.merge(key: key, soft_id: 800)
        )
        validate_response(res)
        res
      end

      # Fail if the response has errors.
      #
      # @param [String] response The body response from TwoCaptcha API.
      #
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