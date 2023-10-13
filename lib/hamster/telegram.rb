# frozen_string_literal: true

module Hamster
  def self.telegram
    log 'Hamster listens Telegram messages'
    Telegram::Bot::Client.run(Storage.new.telegram) do |bot|
      bot.listen do |message|
        puts "id:   #{message.from.id}"
        puts "bot:  #{message.from.is_bot ? 'yes' : 'no'}"
        puts "name: #{message.from.first_name} #{message.from.last_name}"
        puts "nick: #{message.from.username}"
        puts "text: #{message.text}"
      end
    end
  end
end

