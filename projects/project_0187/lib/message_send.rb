def message_send(message)
  task_title = 'Scrape - #187'
  name_to = 'Igor Sas'
  Hamster.report(to: name_to, message: "*#{task_title}*\n#{message.uncolorize}")
end