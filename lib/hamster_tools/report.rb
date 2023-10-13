# frozen_string_literal: true

module Hamster
  module HamsterTools
    def report(to:, message:, use: :slack)
      @_s_    = Storage.new

      if to =~ /U[0-Z]{8}([0-Z]{2})?/ # Check if SlackID is given before searching database (previous value - G[0-Z]{10})
        @_user_ = to
      else
        @_user_ = Scrapers.where("name=:to || nick=:to || slack=:to || telegram=:to", to: to).first
        Hamster.close_connection(Scrapers)
      end

      unless @_user_
        log 'The recipient of the report cannot be found!', :red
        return
      end
      
      case use
      when :slack
        slack_send(message)
      when :telegram
        tg_send(message)
      when :both
        slack_send(message)
        tg_send(message)
      else
        log "Cannot use such messenger as #{use.to_s.capitalize}!", :red
      end
    end
    
    private
    
    def slack_send(text)
      Slack.configure do |config|
        config.token = @_s_.slack
        raise 'Missing Slack API token!' unless config.token
      end
      
      Slack::Web::Client.new.chat_postMessage(channel: @_user_.is_a?(String) ? @_user_: @_user_.slack, text: text, as_user: true)
    end
    
    def tg_send(text)
      message_limit = 4000
      message_count = text.size / message_limit + 1
      Telegram::Bot::Client.run(@_s_.telegram) do |bot|
        message_count.times do
          splitted_text = text.chars
          text_part     = splitted_text.shift(message_limit).join
          bot.api.send_message(chat_id: @_user_.telegram, text: escape(text_part), parse_mode: 'MarkdownV2')
        end
      end
    end
    
    def escape(text)
      text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~`>#+=|{}.!])/, '\\\\\1')
    end
  end
end
