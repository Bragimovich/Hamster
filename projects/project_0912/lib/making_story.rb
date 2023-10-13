# frozen_string_literal: true

STATES_TO_NAME = {"AL"=>"Alabama", "AK"=>"Alaska", "AZ"=>"Arizona", "AR"=>"Arkansas", "CA"=>"California", "CO"=>"Colorado", "CT"=>"Connecticut", "DE"=>"Delaware", "DC"=>"District of Columbia", "FL"=>"Florida", "GA"=>"Georgia", "HI"=>"Hawaii", "ID"=>"Idaho", "IL"=>"Illinois", "IN"=>"Indiana", "IA"=>"Iowa", "KS"=>"Kansas", "KY"=>"Kentucky", "LA"=>"Louisiana", "ME"=>"Maine", "MD"=>"Maryland", "MA"=>"Massachusetts", "MI"=>"Michigan", "MN"=>"Minnesota", "MS"=>"Mississippi", "MO"=>"Missouri", "MT"=>"Montana", "NE"=>"Nebraska", "NV"=>"Nevada", "NH"=>"New Hampshire", "NJ"=>"New Jersey", "NM"=>"New Mexico", "NY"=>"New York", "NC"=>"North Carolina", "ND"=>"North Dakota", "OH"=>"Ohio", "OK"=>"Oklahoma", "OR"=>"Oregon", "PA"=>"Pennsylvania", "RI"=>"Rhode Island", "SC"=>"South Carolina", "SD"=>"South Dakota", "TN"=>"Tennessee", "TX"=>"Texas", "UT"=>"Utah", "VT"=>"Vermont", "VA"=>"Virginia", "WA"=>"Washington", "WV"=>"West Virginia", "WI"=>"Wisconsin", "WY"=>"Wyoming", "PR"=>"Puerto Rico", "AS"=>"American Samoa", "GU"=>"Guam", "MP"=>"Northern Mariana Islands", "UM"=>"U.S. Minor Outlying Islands", "VI"=>"Virgin Islands"}


def count_paragraphs
  loop do
    records = CongressionalRecordJournals.where(paragraphs: nil).where(dirty:0).first(1000)#.all() #where('year(date)=?', 2017).

    records.each do |rec|
      paragraph = "\n  "
      p rec.link
      # delete_first_row

      #dependence_par_to_length = Float(text.split(paragraph).length)/Float(text.length) # dependence paragraphs to length
      #next if dependence_par_to_length*100>4
      #p text.gsub(/\[?.*\]/, '!!!')

      if rec.text.nil?
        rec.dirty = 1
      else
        text = rec.text.split('[www.gpo.gov]')[1]
        text = rec.text if text.nil?
        rec.paragraphs = text.split(paragraph).length
      end

      rec.save
    end
  end
end

def clean_text
  loop do
    records = CongressionalRecordJournals.where(dirty:0).where(clean_text: nil).first(500)

    records.each do |rec|

      paragraph = "\n  "
      if rec.text.nil?
        rec.dirty = 1
      else
        text = rec.text.split('[www.gpo.gov]')[1] # delete_first_row
        text = rec.text if text.nil?

        dependence_par_to_length = Float(text.split(paragraph).length)/Float(text.length) # dependence paragraphs to length

        if dependence_par_to_length*100>4.5
          rec.dirty = 1
        end
        clean_text = text.gsub(/\n\n\[?.*\]\n/, ' ').gsub(/\b \n\b/, " ").gsub(/ \n\s*(?=[a-z])/, " ").gsub(/\n     (?=\w)/, "").gsub(/(?<=.) \n\b/, " ") #for delete pagination #not check
        p rec.link
        rec.clean_text = clean_text.strip if !clean_text.nil?
      end
      rec.save
    end
    break if records.to_a.length<500
  rescue => e
    p e

  end
end

"https://www.congress.gov/congressional-record/2011/4/15/house-section/article/h2861-4"


# def run()
#
#   Dir.entries('/Users/Magusch/HarvestStorehouse/project_0111/test/').each do |filename|
#     next if !filename.match('.htm')
#     path = "/Users/Magusch/HarvestStorehouse/project_0111/test/#{filename}"
#     text = ''
#     File.open(path) {|f| text = f.read}
#     p filename
#     text = text.gsub(/\n\n\[?.*\]\n/, ' ').gsub(/\b \n\b/, ' ').gsub(/ \n\s*(?=[a-z])/, " ").gsub(/\n     \b/, "").gsub(/(?<=.) \n\b/, ' ')
#     p text
#   end
# end

# CongressionalRecordJournals
# CongressionalRecordDepartments
# CongressionalRecordDepartmentsMatching
def get_departaments(days=20)
  matching_names = {}
  CongressionalRecordDepartmentsMatching.all().each { |row| matching_names[row.dept_matching_name]=row.dept_id}
  limit = 1000

  matching_names.each_pair do |name, dept_id|
    p name
    year = 2021
    while year!=1994
      page = 0
      loop do
        offset = limit*page
        records = []
        existing_ids = CongressionalRecordArticleToDepartments.where(dept_id:dept_id).where(article_year:year).map { |art| art.article_id }
        CongressionalRecordJournals.where(dirty:0).where("updated_at>#{Date.today()-days}").where("YEAR(date)=#{year}").where.not(id:existing_ids).where("clean_text like '%#{name}%'").limit(limit).offset(offset).each do |record|
          records.push({dept_id:dept_id, article_id: record.id, article_year:year})
        end
        CongressionalRecordArticleToDepartments.insert_all(records) if !records.empty?
        break if records.length<limit
        page+=1
      end
      year = year - 1
    end

  end
end

# Daily Digest
# Extensions of Remarks
# House of Representatives
# Senate

def get_senators(updated_at_days=10)
  sections = ['Daily Digest', 'Extensions of Remarks', 'Senate']
  limit = 1000
  senate_members = CongressionalRecordSenateMembers.all()
  similar_lastname_members = check_similar_lastname(senate_members)
  senate_members.each do |senate_member|
    bioguide = senate_member.bioguide
    p bioguide
    sim_sigh = 0
    sim_sigh = 1 if senate_member.last_name.in? similar_lastname_members
    regular_string = get_name(senate_member, sim_sigh)
    r="clean_text REGEXP '#{regular_string}'"

    time_intervals = USCongressSenateMembers.where(bioguide: senate_member.bioguide).map {|row| {start:row.start_term.year, end:row.end_term.year}}
    time_intervals.each do |interval|
      (interval[:start]..interval[:end]).each do |year|
        page = 0
        loop do
          offset = limit*page
          records = []
          existing_ids = CongressionalRecordArticleToSenateMember.where(bioguide:bioguide).where(article_year:year).map { |art| art.article_id }
          CongressionalRecordJournals.where(dirty:0).where(section: sections).where("YEAR(date)=#{year}").where("updated_at>#{Date.today()-updated_at_days}").where.not(id:existing_ids).where("clean_text like '%#{senate_member.full_name}%' or clean_text like '%#{senate_member.first_name} #{senate_member.last_name}%'").limit(limit).offset(offset).each do |record|
            records.push({bioguide:bioguide, article_id: record.id, article_year:year})
            existing_ids.push(record.id)
          end
          CongressionalRecordJournals.where(dirty:0).where(section: sections).where("YEAR(date)=#{year}").where("updated_at>#{Date.today()-updated_at_days}").where.not(id:existing_ids).where(r).limit(limit).offset(offset).each do |record|
            records.push({bioguide:bioguide, article_id: record.id, article_year:year})
            existing_ids.push(record.id)
          end
          CongressionalRecordArticleToSenateMember.insert_all(records) if !records.empty?
          break if records.length<limit
          page+=1
        end

      end
    end
  end

end


def get_house_members(updated_at_days=10)
  sections = ['Daily Digest', 'Extensions of Remarks', 'House of Representatives']
  limit = 1000
  house_members = CongressionalRecordHouseMembers.all()
  similar_lastname_members = check_similar_lastname(house_members)

  house_members.each do |house_member|
    bioguide = house_member.bioguide
    p bioguide

    sim_sigh = 0
    sim_sigh = 1 if house_member.last_name.in? similar_lastname_members
    regular_string = get_name(house_member, sim_sigh)

    r="clean_text REGEXP '#{regular_string}'"

    time_intervals = USCongressHouseMembers.where(bioguide: house_member.bioguide).map {|row| {start:row.start_term.year, end:row.end_term.year}}
    time_intervals.each do |interval|
      (interval[:start]..interval[:end]).each do |year|
        page = 0
        loop do
          offset = limit*page
          records = []
          existing_ids = CongressionalRecordArticleToHouseMember.where(bioguide:bioguide).where(article_year:year).map { |art| art.article_id }
          CongressionalRecordJournals.where(dirty:0).where(section: sections).where("YEAR(date)=#{year}").where("updated_at>#{Date.today()-updated_at_days}")
                                     .where.not(id:existing_ids).where("clean_text like '%#{house_member.full_name}%' or clean_text like '%#{house_member.first_name} #{house_member.last_name}%'").limit(limit).offset(offset).each do |record|
            records.push({bioguide:bioguide, article_id: record.id, article_year:year})
            existing_ids.push(record.id)
          end

          CongressionalRecordJournals.where(dirty:0).where(section: sections).where("YEAR(date)=#{year}").where("updated_at>#{Date.today()-updated_at_days}")
                                     .where.not(id:existing_ids).where(r).limit(limit).offset(offset).each do |record|
            records.push({bioguide:bioguide, article_id: record.id, article_year:year})
            existing_ids.push(record.id)
          end
          CongressionalRecordArticleToHouseMember.insert_all(records) if !records.empty?
          break if records.length<limit
          page+=1
        end
      end
    end
  end
end


def get_name(member, sim_sigh=0)
  if member.gender=='F'
    presentations = ['Ms', 'Mrs', 'Congresswoman']
  elsif member.gender=='M'
    presentations = ['Mr']
  end
  presentations.push('Congressman', 'Senators?')

  # regular: Mr and Mrs to last_name
  regular_string = '((' + presentations.join(')|(') + "))."
  regular_string += "?#{member.last_name}[\\. ]" if sim_sigh==0
  regular_string += "?#{member.last_name} of #{STATES_TO_NAME[member.state]}" if sim_sigh==1

  # with state
  regular_string = "(#{regular_string})|(#{member.last_name} (of|for|from) #{STATES_TO_NAME[member.state]})"


  # p regular_string
  # #q='fdsfds Mrs. GGGG qqqq'
  # q = 'fdsfdsfds Senator Lummis. vvvv'
  # p /#{regular_string}/.match(q)
  regular_string
end


def check_similar_lastname(members)
  similar_lastname = []
  all_lastname = []
  members.each do |m|
    similar_lastname.push(m.last_name) if m.last_name.in? all_lastname
    all_lastname.push(m.last_name)
  end
  similar_lastname
end