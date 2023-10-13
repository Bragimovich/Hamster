# frozen_string_literal: true

module UnexpectedTasks
  module UsCourts
    class CaseMatcher
      ACTIVITY_TYPES = [
        'a final judgment',
        'an interlocutory judgment',
        'affadavit of indigency',
        'affidavit of facts',
        'affidavit of service',
        'certificate of merit',
        'certificate of probable cause',
        'confession of judgment',
        'counter complaint',
        'demand for bill of particulars',
        'discovery motion',
        'habeas corpus',
        'interlocutory application',
        'judgment by confession',
        'judgment by default',
        'judgment by nil dicit',
        'judgment by non sum informatus',
        'judgment in action on the case for trover',
        'judgment in actions on the case for torts',
        'judgment in an action on trespass',
        'judgment in assumpsit',
        'judgment in covenant',
        'judgment in error',
        'judgment in replevin',
        'judgment in the action of debt',
        'judgment in the action of detinue',
        'judgment of capiatur',
        'judgment of misericordia',
        'judgment of nil capiat (per breve|per billam)',
        'judgment of nolle prosequi',
        'judgment of non obstante veredicto',
        'judgment of non pros',
        'judgment of nonsuit',
        'judgment of respondeat ouster',
        'judgment of retraxit',
        'judgment quod computet',
        'judgment quod partes replacitent',
        'judgment quod partitio fiat',
        'judgment quod recuperet',
        'judgment',
        'judgment of cassetur (breve|billa)',
        'motion denied',
        'motion for a directed verdict',
        'motion for nolle prosequi',
        'motion for summary (judgment|disposition)',
        'motion in limine',
        'motion to appoint receiver',
        'motion to postpone sentencing',
        'motion to compel',
        'motion to dismiss',
        'motion to strike',
        'motion to waive fee',
        'notice of appeal',
        'notice of deposition',
        'notice of discontinuance',
        'notice of pendency',
        'order',
        'order extending time',
        'summons|complaint',
        'taken under advisement',
        'writ of certiorari'
      ]
      
      def self.run(**options)
        file_name = 'court_activities.csv'
        courts    = 'SELECT court_id, court_name FROM us_courts_table ORDER BY court_id, court_name'
        usa_raw   = Mysql2::Client.new(Storage[host: :db01, db: :usa_raw].merge(symbolize_keys: true))
        
        usa_raw.query('USE usa_raw')
        
        File.write(file_name, "court id,court name,activity type,count\n", mode: 'a')
        
        usa_raw.query(courts).to_a.each do |court|
          ACTIVITY_TYPES.each do |activity|
            count  = "SELECT count(*) number FROM us_case_activities WHERE court_id = #{court[:court_id]} AND activity_decs RLIKE('#{activity}')"
            count  = usa_raw.query(count).to_a.first
            string = "#{court[:court_id]},#{court[:court_name]},#{activity.upcase},#{count[:number]}\n"
            File.write(file_name, string, mode: 'a')
            print string
          end
        end
        
        usa_raw.close
      end
    end
  end
end
