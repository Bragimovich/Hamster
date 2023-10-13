def message_send(title, message, name_to = 'Igor Sas')
  Hamster.report(to: name_to, message: "*#{title}*\n#{message.uncolorize}")
end