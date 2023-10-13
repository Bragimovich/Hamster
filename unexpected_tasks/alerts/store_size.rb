require_relative 'models/scrape_tasks'
require_relative 'models/messages'
require_relative 'tools/converter'
require 'google_drive'

module UnexpectedTasks
  module Alerts
    class StoreSize

      def self.run(**options)
        channel = "C04NVKP3SSX" #hamster_managers
        #channel = "C03RTH1G6P3" #test
        channel2 = "G01CY84KMT6" #hle_scrape_devs
        #channel2 = "C03RTH1G6P3" #test
        server = options['server'].blank? ? "loki01" : options['server']
        docker = options['docker'] ? '(in docker) ' : ''
        df_h = %x[df / | grep /]
        df_h = df_h.split("\n")[0].squeeze(' ').split(" ")
        df_h = {
          total: df_h[1].to_i,
          usage: df_h[2].to_i,
          free: df_h[3].to_i,
          percent: df_h[4]
        }
        tasks = ScrapeTasks.connection.execute("SELECT st.id, sa.identifier, sa.user_name FROM scrape_tasks AS st JOIN slack_accounts AS sa ON sa.account_id = st.scraper_id WHERE st.scraper_id is not null")
        total = []
        tasks.each do |task|
          task_id = task[0]
          slack = task[1]
          name = task[2]
          size = %x[cd ~/HarvestStorehouse/project_#{format('%04d', task_id)} && du -s]
          size = size.squeeze(' ').split(' ')[0].gsub(/\D/,'').to_i unless size.blank?
          unless size.blank?
            if size > 1048576
              Hamster.logger.info "ALERT! project_#{format('%04d', task_id)} = #{convert(size)} - is BIG!".red
              message = "*:alert: ALERT! :alert:*"
              message += "\nYou `~/HarvestStorehouse/project_#{format('%04d', task_id)}` #{docker}folder on _#{server}_ is *very big* `#{convert(size)}` out of *1 GB* allowed!"
              if server == 'hamster01'
                message += "\n*Contact with your manager to free disk space*"
              else
                message += "\n*Reduce the folder size as soon as possible!*"
              end
              message += "\nCC: <@ULCFVUK44>"
              Hamster.report(to: slack, message: message)
              Hamster.logger.info "Message send to PM #{name} (#{slack})".blue
              total << {size: size, slack: slack, task_id: task_id, name: name}
            else
              Hamster.logger.info "project_#{format('%04d', task_id)} = #{convert(size)} - is NORMAL".green
            end
          end
        end
        credentials = Google::Auth::UserRefreshCredentials.new(Storage.new.auth_hamster)
        session = GoogleDrive::Session.from_credentials(credentials)
        spreadsheet = session.spreadsheet_by_key('1fr81EjbuFX9MZ14kQqGeVJIQD5iJUcXmcd29C4e_IBs')
        if options['docker']
          worksheet = spreadsheet.worksheets.find {|i| i.title == 'HarvestStorehouse in DOCKER'}
        else
          worksheet = spreadsheet.worksheets.find {|i| i.title == 'HarvestStorehouse'}
        end
        num_rows = worksheet.num_rows
        datetime = DateTime.now
        date = datetime.strftime('%d.%m.%Y %H:%M:%S')
        if total.blank?
          text = ":meow-popcorn: *HarvestStorehouse #{docker}folders. All scrapers adhere to the limit. _It's fine!_*"
          worksheet[num_rows + 1, 1] = date
          worksheet[num_rows + 1, 2] = 'All scrapers adhere to the limit.'
          worksheet[num_rows + 1, 5] = "Space usage: #{convert(df_h[:usage])}/#{convert(df_h[:total])} (#{df_h[:percent]})"
        else
          free = total.map{|item| item[:size] > 1048576 ? item[:size] - 1048576 : nil}.compact.sum
          text = ":this-is-fine-fire: *HarvestStorehouse #{docker}folders size warning! (can be free `#{convert(free)}`)*"
          text += "\n> Space usage on server: #{convert(df_h[:usage])}/#{convert(df_h[:total])} (#{df_h[:percent]})"
          text2 = ''
          total.sort_by!{|item| item[:size]}.reverse!
          total[0..4].each_with_index do |item, index|
            text2 += "\n#{index + 1}. <@#{item[:slack]}> - `~/HarvestStorehouse/project_#{format('%04d', item[:task_id])}` #{docker}folder on _#{server}_ size = `#{convert(item[:size])}`" if df_h[:percent].gsub('%','').to_i <= 88 && item[:size] > 5242880
            text2 += "\n#{index + 1}. <@#{item[:slack]}> - `~/HarvestStorehouse/project_#{format('%04d', item[:task_id])}` #{docker}folder on _#{server}_ size = `#{convert(item[:size])}`" if df_h[:percent].gsub('%','').to_i > 88
          end
          text = text2.blank? ? nil : text + text2
          worksheet[num_rows + 1, 1] = date
          worksheet[num_rows + 1, 2] = "Can be free: #{convert(free)}"
          worksheet[num_rows + 1, 5] = "Space usage: #{convert(df_h[:usage])}/#{convert(df_h[:total])} (#{df_h[:percent]})"
        end
        num_rows += 2
        total.each_with_index do |item, index|
          worksheet[num_rows + index, 1] = date
          worksheet[num_rows + index, 2] = server
          worksheet[num_rows + index, 3] = "~/HarvestStorehouse/project_#{format('%04d', item[:task_id])}"
          worksheet[num_rows + index, 4] = convert(item[:size])
          worksheet[num_rows + index, 5] = item[:name]
          worksheet[num_rows + index, 6] = "=HYPERLINK(\"https://locallabs.slack.com/team/#{item[:slack]}\";\"@#{item[:name]}\")"
        end
        worksheet.save
        worksheet.reload
        Hamster.logger.info 'Spreadsheet updated!'.blue
        Slack.configure do |config|
          config.token = Storage.new.slack
        end
        if total.blank? || text.blank?
          timestamp = nil
          channel = nil
        else
          timestamp = Slack::Web::Client.new.chat_postMessage(channel: channel, text: text, as_user: true)
          timestamp = timestamp[:ts]
          Hamster.logger.info "Message send to channel #{channel}".blue
        end
        Messages.insert({channel: channel, timestamp: timestamp, message: text, date: datetime})
        if df_h[:percent].gsub('%','').to_i > 88
          if total.blank? || text.blank?
            timestamp = nil
            channel2 = nil
          else
            timestamp = Slack::Web::Client.new.chat_postMessage(channel: channel2, text: text, as_user: true)
            timestamp = timestamp[:ts]
            Hamster.logger.info "Message send to channel #{channel}".blue
          end
          Messages.insert({channel: channel2, timestamp: timestamp, message: text, date: datetime})
        end
        old_messages = Messages.where("date < '#{datetime - 11.hours}' AND deleted = 0 AND channel IS NOT NULL AND timestamp IS NOT NULL").to_a
        old_messages.each do |mess|
          timestamp = mess[:timestamp]
          channel = mess[:channel]
          Hamster.logger.info "Delete message #{timestamp} from channel #{channel}".red
          Slack::Web::Client.new.chat_delete(channel: channel, ts: timestamp, as_user: true)
        rescue => e
          message = "Error: #{e.message}"
          Hamster.logger.error message
        end
        Messages.where("date < '#{datetime - 11.hours}' AND deleted = 0").update(deleted: 1)
        Hamster.logger.info 'Delete messages mark deleted = 1!'.blue
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        Hamster.logger.error message
      end
    end
  end
end
