require_relative 'lib/manager'

def scrape(options)
  manager = Manager.new
  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  end
rescue => e
  Hamster.report(to: 'vyacheslav pospelov', message: "Project # 0455 --download: Error - \n#{e.full_message} ", use: :both)
  puts ['*'*77, "\n", e.full_message]
end