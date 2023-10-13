# frozen_string_literal: true

require_relative '../models/schools'
require_relative '../models/persons'
require_relative '../models/contacts'
require_relative '../models/run'
require_relative '../models/games'
require_relative '../models/school_alias'
require_relative '../models/final_result_additions_desc'
require_relative '../models/final_result_score_by_innings'
require_relative '../models/final_result_score_details'
require_relative '../models/final_result_scores_players'

class Keeper < Hamster::Keeper

  def initialize
    @run_object = safe_operation(Run) { |model| RunId.new(model) }
    @run_id = safe_operation(Run) { @run_object.run_id }
  end

  attr_reader :run_id

  def insert_school_data(data_hash)
    school = data_hash['school']
      unless School.where(data_source_url: school['data_source_url']).first
        contact = data_hash['school_contact']
        contact_record = Contact.where(website: contact['website'], full_address: contact['full_address'], email: contact['email'], fax: contact['fax'], phone: contact['phone']).first
        if contact_record
          school['contact_id'] = contact_record.id
        else
          Contact.insert(contact)
          school['contact_id'] = Contact.last.id
        end
        School.insert(school) 
        school_id = School.last.id
        logger.info "------------------- Inserted School's data -------------------"
        persons_contacts = data_hash['persons_and_contact']
        persons_contacts.each do |person_contact|
          person = person_contact.first
          contact = person_contact.last
          person_record = Person.where(data_source_url: person['data_source_url'], vacation: person['vacation'], section: person['section'], full_name: person['full_name']).first
          unless person_record
            person['school_id'] = school_id
            if contact['phone'].nil? and contact['email'].nil? and contact['fax'].nil?
              Person.insert(person)
            else
              contact_record = Contact.where(email: contact['email'], fax: contact['fax'], phone: contact['phone']).first
              if contact_record
                person['contact_id'] = contact_record.id
              else
                Contact.insert(contact)
                person['contact_id'] = Contact.last.id
              end
              Person.insert(person)
            end
            logger.info "------------------- Inserted Person's data -------------------"
          else 
            logger.info "------------------- Already Present Person -------------------"
          end
        end
      else 
    end
    logger.info "------------------- Already Present School -------------------"
  end

  def insert_baseball_data(data_hash)
    players = data_hash['Players_Scores']
    inning_score = data_hash['Innings']
    description_data = data_hash['Description']
    player_score_details = data_hash['Scores_Details']
    players.each do |player|
      player_details = player.first  
      player_scores = player.last
      player_scores['ex_player_name'] = player_details['full_name']       
      FinalResultScorePlayer.insert(player_scores)          
    end

    inning_score.each do |inning|
      FinalResultScoreByInning.insert(inning)
    end

    description_data.each do |description|
      FinalResultAdditionsDesc.insert(description)
    end

    player_score_details.each do |player_score_detail|
      FinalResultScoreDetail.insert(player_score_detail)
    end

  end

  def insert_alias_data(data_hash)
    SchoolAlias.insert(data_hash)
  end

  def get_school_id_by_aliase_name(aliase_name)
    school = School.select{|e| e.name == aliase_name }.first
    data_source_url = school.data_source_url rescue nil
    school_id = school.id rescue nil
    [school_id, data_source_url]
  end

  def get_school_id_by_url(url)
    school = School.select{|e| e.data_source_url == url }.first 
    school_id = school.id rescue nil
  end

  def already_procssed_schools
    School.pluck(:data_source_url)
  end

  def get_all_schools
    School.all
  end

  def fix_games_data
    schools = School.all
    alias_table = SchoolAlias.all
    schools_data = FinalResultScoreByInning.all

    games = Game.where(comand_1: nil).or(Game.where(comand_2: nil)).or(Game.where(score_command_1: nil)).or(Game.where(score_command_2: nil)).and(Game.where("section LIKE 'State Final Tournament%'")).all
    games.each do |game|
      current_school = schools_data.select{|e| e.game_id == game.id}
      next if current_school.empty?
      
      if game.comand_1.nil?
        comand_1 = current_school.first.school_id
        if comand_1
          game.update(comand_1: comand_1, deleted: 1)
        else
          logger.error "No school found with name '#{comand_1}'"
        end
      end

      if game.comand_2.nil?
        comand_2 = current_school.last.school_id
        if comand_2
          game.update(comand_2: comand_2, deleted: 1)
        else
          logger.error "No school found with name '#{comand_2}'"
        end
      end
      
      if game.score_command_1.nil?
        score_row_1 = current_school.first.ex_school_score_1.split(/^.*\s(\d+)(?:\s\(\d+-\d+(?:-\d+)?\))?$/)
        if score_row_1.count > 2
          comand_1_score = score_row_1.second.split.first.strip.to_i
        else
          comand_1_score = score_row_1.last.split.first.strip.to_i
        end
        if comand_1_score
          game.update(score_command_1: comand_1_score, deleted: 1)
        else
          logger.error "No school found with name '#{comand_1}"
        end
      end
      
      if game.score_command_2.nil?
        score_row_2 = current_school.last.ex_school_score_2.split(/^.*\s(\d+)(?:\s\(\d+-\d+(?:-\d+)?\))?$/)
        if score_row_2.count > 2
          comand_2_score = score_row_2.second.split.first.strip.to_i
        else
          comand_2_score = score_row_2.last.split.first.strip.to_i
        end
        if comand_2_score
          game.update(score_command_2: comand_2_score, deleted: 1)
        else
          logger.error "No school found with name '#{comand_2}"
        end
      end
      logger.info "School #{current_school.last.data_source_url}"
      logger.info "Game #{game.data_source_url}"
    end

    all_games = Game.where(section: "State Final Tournament").all
    all_games.each do |game|
      current_school = schools_data.select{|e| e.game_id == game.id}
      next if current_school.empty?
      sec = current_school.first.ex_raw_data.split(/((Class|IHSA)\s*\d.\s*(\-|\\x96|\s*)\s*)/).last.split("Game").first.split(/\#\d*/).first.strip.concat(" Game")
      section = "State Final Tournament - #{sec}"
      game.update(section: section)
    end
    logger.info "GAMES"
  end

  def update_relations
    @schools = School.all
    @persons = Person.all
    @games   = Game.all
    @alias_table = SchoolAlias.all
    add_school_id_in_players
    add_person_id_in_players
    add_game_id_in_players
    add_school_id_in_innings
    add_game_id_in_innings
    add_school_id_in_details
    add_inning_id_in_details
    add_person_id_in_details
    add_game_id_in_desc
  end

  def add_school_id_in_players
    score_players = FinalResultScorePlayer.where(school_id: nil).all
    score_players.each do |score_player|
      school_name = score_player.ex_school_name.tr("()","").downcase.strip 
      school = @schools.select{|e| e.name.tr("()","").downcase.strip == school_name}.first 
      if school.nil?
        school = @alias_table.select{|e| e.aliase_name.tr("()","").downcase.strip == school_name}.first
        school_ki_id = school.school_id rescue nil
      end
      if school
        if school_ki_id != nil
          school_id = school_ki_id  
        else
          school_id = school.id
        end
        score_player.update(school_id: school_id)
        logger.info "Updated school_id for #{score_player.id} #{score_player.ex_school_name}"
      else
        school = @schools.select{|e| e.name.tr("()","").downcase.strip.include? school_name}.first 
        if school.nil?
          school = @alias_table.select{|e| e.aliase_name.tr("()","").downcase.strip.include? school_name}.first 
          school_ki_id = school.school_id
        end
        if school
          if school_ki_id != nil
            school_id = school_ki_id  
          else
            school_id = school.id
          end
          score_player.update(school_id: school_id)
          logger.info "Updated school_id for #{score_player.id} #{score_player.ex_school_name}"
        else
          logger.error "No school found with name '#{school_name}'"
        end
      end
    end
  end

  def add_person_id_in_players
    score_players = FinalResultScorePlayer.where(person_id: nil).all
    score_players.each do |score_player|
      school_id = score_player.school_id
      player_name = score_player.ex_player_name 
      school_name = score_player.ex_school_name 

      if school_id
        person = @persons.select{|e| e.school_id == school_id && e.section == 'Roster' && e.full_name.tr("()","").downcase.strip.include?(player_name.tr("()","").downcase.strip)}.first
      else  
        person = @persons.select{|e| e.section == 'Roster' && e.ex_school_name == school_name && e.full_name.tr("()","").downcase.strip.include?(player_name.tr("()","").downcase.strip) }.first
      end

      if person
        person_id = person.id
        score_player.update(person_id: person_id)
        logger.info "Updated persons_id for #{score_player.id} #{score_player.ex_school_name}"
      else
        if school_id
          person = Person.create(full_name: player_name, first_name: player_name.split.first, last_name: player_name.split.last, school_id: school_id, section: 'Roster', data_source_url: score_player.data_source_url, run_id: score_player.run_id) rescue nil
          @persons = Person.all
          if person
            person_id = person.id
            score_player.update(person_id: person_id)
            logger.info "Updated persons_id for #{score_player.id} #{score_player.ex_school_name}"
          else
            logger.error "No player found with name '#{player_name}'"
          end
        else
          person = Person.create(full_name: player_name, first_name: player_name.split.first, last_name: player_name.split.last, ex_school_name: school_name, section: 'Roster', data_source_url: score_player.data_source_url, run_id: score_player.run_id) rescue nil
          @persons = Person.all
          if person
            person_id = person.id
            score_player.update(person_id: person_id)
            logger.info "Updated persons_id for #{score_player.id} #{score_player.ex_school_name}"
          else
            logger.error "No player found with name '#{player_name}'"
          end
        end
      end
    end
  end

  def add_game_id_in_players
    score_players = FinalResultScorePlayer.where(game_id: nil).all
    score_players.each do |score_player|

      game_url = score_player.data_source_url.gsub("www.","").gsub("://","://www.").gsub(/box./,'pair')
      game_number = score_player.data_source_url.gsub(/^\S*box/,"").gsub(".htm","").to_i

      date = score_player.ex_raw_data.scan(/[a-zA-Z]{3,}\s*\d{1,2},*\s*\d{2,}/).first
      date = Date.parse(date).to_s if date

      unless date
        date = score_player.ex_raw_data.scan(/\d{1,2}\/\d{1,2}\/\d{2}/).first
        date = Date.strptime(date, '%m/%d/%y').to_s if date
      end

      unless date
        date = score_player.ex_raw_data.scan(/\d{1,2}\/\d{1,2}\/\d{4}/).first unless date
        date = Date.strptime(date, '%m/%d/%Y').to_s if date
      end
      
      if date
        game = @games.select{|e| e.date.to_s == date && e.data_source_url == game_url && e.game_number == game_number }
        game = game.first
        if game
          score_player.update(game_id: game.id)
          logger.info "Updated game_id for #{score_player.id} #{score_player.ex_school_name}"
        else
          game = @games.select{|e| e.data_source_url == game_url && e.game_number == game_number && e.section.include?("State Final Tournament")}
          game = game.first
          if game
            score_player.update(game_id: game.id)
            logger.info "Updated game_id for #{score_player.id} #{score_player.ex_school_name}"
          else
            logger.error "Game Not Found"
          end
        end
      else
        logger.error "Date Not Found"
      end
    end
  end

  def add_school_id_in_innings
    logger.info "adding_school_id_in_innings"
    innings = FinalResultScoreByInning.where(school_id: nil).all
    innings.each do |inning|
      school_name = inning.ex_school_name.tr("()","").downcase.strip 
      school = @schools.select{|e| e.name.tr("()","").downcase.strip == school_name}.first 
      if school.nil?
        school = @alias_table.select{|e| e.aliase_name.tr("()","").downcase.strip == school_name}.first
        school_ki_id = school.school_id
      end
      if school
        if school_ki_id != nil
          school_id = school_ki_id  
        else
          school_id = school.id
        end
        inning.update(school_id: school_id)
        logger.info "Updated school_id for #{inning.id} | #{inning.ex_school_name}"
      else
        school = @schools.select{|e| e.name.tr("()","").downcase.strip.include? school_name}.first 
        if school.nil?
          school = @alias_table.select{|e| e.aliase_name.tr("()","").downcase.strip.include? school_name}.first 
          school_ki_id = school.school_id
        end
        if school
          if school_ki_id != nil
            school_id = school_ki_id  
          else
            school_id = school.id
          end
          inning.update(school_id: school_id) 
          logger.info "Updated school_id for #{inning.id} | #{inning.ex_school_name}"
        else
          logger.error "No school found with name '#{school_name}'"
        end
      end
    end
  end

  def add_game_id_in_innings
    innings = FinalResultScoreByInning.where(game_id: nil).all
    innings.each do |inning|

      game_url = inning.data_source_url.gsub("www.","").gsub("://","://www.").gsub(/box./,'pair')
      game_number = inning.data_source_url.gsub(/^\S*box/,"").gsub(".htm","").to_i

      date = inning.ex_raw_data.scan(/[a-zA-Z]{3,}\s*\d{1,2},*\s*\d{2,}/).first
      date = Date.parse(date).to_s if date

      unless date
        date = inning.ex_raw_data.scan(/\d{1,2}\/\d{1,2}\/\d{2}/).first
        date = Date.strptime(date, '%m/%d/%y').to_s if date
      end

      unless date
        date = inning.ex_raw_data.scan(/\d{1,2}\/\d{1,2}\/\d{4}/).first unless date
        date = Date.strptime(date, '%m/%d/%Y').to_s if date
      end
      
      if date
        game = @games.select{|e| e.date.to_s == date && e.data_source_url == game_url && e.game_number == game_number }
        game = game.first
        if game
          inning.update(game_id: game.id)
          logger.info "Updated game_id for #{inning.id} #{inning.ex_school_name}"
        else
          game = @games.select{|e| e.data_source_url == game_url && e.game_number == game_number && e.section.include?("State Final Tournament")}
          game = game.first
          if game
            inning.update(game_id: game.id)
            logger.info "Updated game_id for #{inning.id} #{inning.ex_school_name}"
          else
            logger.error "Game Not Found"
          end
        end
      else
        logger.error "Date Not Found"
      end
    end
  end

  def add_school_id_in_details
    score_details = FinalResultScoreDetail.where(school_id: nil).all
    score_details.each do |score_detail|
      school_name = score_detail.ex_school_name.tr("()","").downcase.strip 
      school = @schools.select{|e| e.name.tr("()","").downcase.strip == school_name}.first 
      if school.nil?
        school = @alias_table.select{|e| e.aliase_name.tr("()","").downcase.strip == school_name}.first
        school_ki_id = school.school_id
      end
      if school
        if school_ki_id != nil
          school_id = school_ki_id  
        else
          school_id = school.id
        end
        score_detail.update(school_id: school_id)
        logger.info "Updated school_id for #{score_detail.id} #{score_detail.ex_school_name}"
      else
        school = @schools.select{|e| e.name.tr("()","").downcase.strip.include? school_name}.first 
        if school.nil?
          school = @alias_table.select{|e| e.aliase_name.tr("()","").downcase.strip.include? school_name}.first 
          school_ki_id = school.school_id
        end
        if school
          if school_ki_id != nil
            school_id = school_ki_id  
          else
            school_id = school.id
          end
          score_detail.update(school_id: school_id)
          logger.info "Updated school_id for #{score_detail.id} #{score_detail.ex_school_name}"
        else
          logger.error "No school found with name '#{school_name}'"
        end
      end
    end
  end

  def add_inning_id_in_details
    innings = FinalResultScoreByInning.all
    score_details = FinalResultScoreDetail.where(final_result_score_by_inning_id: nil).all
    score_details.each do |score_detail|
      school_name = score_detail.ex_school_name.tr("()","").downcase.strip
      url = score_detail.data_source_url
      inning = innings.select{|e| e.data_source_url == url and e.ex_school_name.tr("()","").downcase.strip.include? school_name}.first
      if inning
        inning_id = inning.id
        score_detail.update(final_result_score_by_inning_id: inning_id)
        logger.info "Updated for inning #{score_detail.id} #{score_detail.ex_school_name}"
      else
        logger.error "No school found with name '#{school_name}'"
      end
    end
  end

  def add_person_id_in_details 
    score_details = FinalResultScoreDetail.where(person_id: nil).all
    score_details.each do |score_detail|
      school_id = score_detail.school_id
      player_name = score_detail.ex_player_name
      school_name = score_detail.ex_school_name

      if school_id
        person = @persons.select{|e| e.school_id == school_id && e.section == 'Roster' && e.full_name.tr("()","").downcase.strip.include?(player_name.tr("()","").downcase.strip) }.first
      else  
        person = @persons.select{|e| e.section == 'Roster' && e.ex_school_name == school_name && e.full_name.tr("()","").downcase.strip.include?(player_name.tr("()","").downcase.strip) }.first
      end

      if person
        person_id = person.id
        score_detail.update(person_id: person_id)
        logger.info "Updated persons_id for  #{score_detail.id} #{score_detail.ex_school_name}"
      else
        if school_id
          person = Person.create(full_name: player_name, first_name: player_name.split.first, last_name: player_name.split.last, school_id: school_id, section: 'Roster', data_source_url: score_detail.data_source_url, run_id: score_detail.run_id) rescue nil
          @persons = Person.all
          if person
            person_id = person.id
            score_detail.update(person_id: person_id)
            logger.info "Updated persons_id for #{score_detail.id} #{score_detail.ex_school_name}"
          else
            logger.error "No player found with name '#{player_name}'"
          end
        else
          person = Person.create(full_name: player_name, first_name: player_name.split.first, last_name: player_name.split.last, ex_school_name: school_name, section: 'Roster', data_source_url: score_detail.data_source_url, run_id: score_detail.run_id) rescue nil
          @persons = Person.all
          if person
            person_id = person.id
            score_detail.update(person_id: person_id)
            logger.info "Updated persons_id for #{score_detail.id} #{score_detail.ex_school_name}"
          else
            logger.error "No player found with name '#{player_name}'"
          end
        end
      end
    end
  end

  def add_game_id_in_desc
    descriptions = FinalResultAdditionsDesc.where(game_id: nil).all
    descriptions.each do |description|

      game_url = description.data_source_url.gsub("www.","").gsub("://","://www.").gsub(/box./,'pair')
      game_number = description.data_source_url.gsub(/^\S*box/,"").gsub(".htm","").to_i

      date = description.ex_raw_data.scan(/[a-zA-Z]{3,}\s*\d{1,2},*\s*\d{2,}/).first
      date = Date.parse(date).to_s if date

      unless date
        date = description.ex_raw_data.scan(/\d{1,2}\/\d{1,2}\/\d{2}/).first
        date = Date.strptime(date, '%m/%d/%y').to_s if date
      end

      unless date
        date = description.ex_raw_data.scan(/\d{1,2}\/\d{1,2}\/\d{4}/).first unless date
        date = Date.strptime(date, '%m/%d/%Y').to_s if date
      end
      
      if date
        game = @games.select{|e| e.date.to_s == date && e.data_source_url == game_url && e.game_number == game_number }
        game = game.first
        if game
          description.update(game_id: game.id)
          logger.info "Updated game_id for #{description.id}"
        else
          game = @games.select{|e| e.data_source_url == game_url && e.game_number == game_number && e.section.include?("State Final Tournament")}
          game = game.first
          if game
            description.update(game_id: game.id)
            logger.info "Updated game_id for #{description.id}"
          else
            logger.error "Game Not Found"
          end
        end
      else
        logger.error "Date Not Found"
      end
    end
  end
  
  def finish
    @run_object.finish
  end
  
  def safe_operation(model, retries=10) 
    begin
      yield(model) if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.info "#{e.class}"
        logger.info '*'*77, "Reconnect!", '*'*77
        sleep 100
        model.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end
    retry
    end
  end

  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end

end
