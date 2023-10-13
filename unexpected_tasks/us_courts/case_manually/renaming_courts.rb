require_relative 'db_models'

module UnexpectedTasks
  module UsCourts
    module CaseManually
      class RenamingCourts
        def self.run(**options)
          self.start
        end

        def self.start
          courts= self.courts_text
          update_str = ""
          courts.each_line do |line|
            if line.match('staging')
              numbers_string = line.split('staging')[-1]
              finish_court_id = numbers_string.split('=>')[-1].strip
              courts = numbers_string.split('+').map { |q| q.to_i }
            elsif line.match('raw')
              numbers_string = line.split('raw')[-1]
              finish_court_id = numbers_string.split('=>')[-1].strip.to_i
              courts = numbers_string.split('+').map { |q| q.to_i }
              ff = NewCourtsTable.where(court_id:courts).map { |row| row.court_id }.join(',')
              update_str += "UPDATE new_courts_table SET court_id=#{finish_court_id} WHERE court_id in (#{ff});"
            end
            #p courts
            #p finish_court_id

          end
          puts
          p update_str
        end



        def self.courts_text
          '# staging 369 + 374 + 353 => 190
                  # raw 1290 + 1269 + 1285 => 95
                  # staging 367 => 370
                  # raw 1283 => 1286
                  # staging 303 + 305 => 170
                  # raw 1217 + 1219 => 72
                  # staging 306 + 304 => 174
                  # raw 1220 + 1218 => 80
                  # staging 359 => 186
                  # raw 1275 => 91
                  # staging 385 => 82
                  # raw 1301 => 232
                  # staging 390 => 383
                  # raw 1306 => 1299
                  # staging 376 => 263
                  # raw 1292 => 1177
                  # staging 388 => 15
                  # raw 1304 => 17
                  # staging 252 => 117
                  # raw 1166 => 322
                  # staging 380 => 7
                  # raw 1296 => 8
                  # staging 308 => 120
                  # raw 1222 => 339
                  # staging 293 + 292 => 287
                  # raw 1206 + 1207 => 1201'
        end
      end
    end
  end
end



