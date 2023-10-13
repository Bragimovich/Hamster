

module Hamster
  module CaptchaAdapter
    class Model
      def initialize(values = {})
        values.each do |key, value|
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end
    end
    
    class Captcha < CaptchaAdapter::Model
      attr_accessor :id, :text, :api_response

      def indexes
        text.gsub('click:', '').split(/[^0-9]/).map(&:to_i)
      end

      def coordinates
        text.scan(/x=([0-9]+),y=([0-9]+)/).map { |x, y| [x.to_i, y.to_i] }
      end
    end
  end
end
