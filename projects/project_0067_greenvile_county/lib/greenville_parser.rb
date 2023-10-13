# frozen_string_literal: true

class GreenvilleParser
  attr_reader :info, :lawyer, :party, :activities, :judgements
  def initialize(html_doc)
    @doc = Nokogiri::HTML(html_doc)
    @info = Hash.new() #Done + Court
    @party = Array.new()
    @activities = Array.new() #Done
    @judgements = Array.new()
    get_info
    #p @info
    get_judgement

    get_action_table
    get_party
    #p @activities

  end

  RENAME_COLUMNS = {
    :info => {
      "Charge Code - Charge Description" => 'case_description',
      "Case Number:" => 'case_id',
      "Filed Date:" => "case_filed_date",
      "Status:" => "status_as_of_date",
      "Assigned Judge:" => "judge_name",
      "Case Type:" => "case_type",
      "Disposition:" => "disposition_or_status",
    },
    :activities => {
      "Begin Date" => :activity_date,
      "Description" => :activity_decs,
      "Type" => :acitivity_type,
      :activity_pdf => :activity_pdf,
      "Name" => :party_name
    },
    :judgement => {
      'Judg. Amount:' => :judgment_amount,
      "Judgment Date:" => :judgment_date,
      'Against:' => :party_name,
      'Detail Amount' => :fee_amount,
      'Description:' => :activity_type
    }
  }

  LAWYERS_TYPES = {
    :Plantiff => ['Appellant', 'Solicitor', 'Plaintiff', 'Plaintiff Attorney'],
    :Defendant => ['Defendant']
  }

  def get_info
    @info[:case_name] = @doc.css('.detailsCaption')[0].content
    @info[:case_id] = @doc.css('.dataValue')[0].content #todo take from parameters


    @doc.css('.detailsSection').css('tr').each do |link|
      #puts link.content.strip
    end
    column_name_panelsection2 = Array.new()
    @doc.css('[@id="ContentPlaceHolder1_PanelSection2"] [@class="columnHeadings"]').css('th').each { |q| column_name_panelsection2.push(q.content) }
    o=0

    figart = Hash.new()
    o = 0
    list_name = []
    @doc.css('[@id="ContentPlaceHolder1_PanelDetails"]').css('td').each do |q| #todo: переделать!!!!
      #@info[column_name_panelsection2[o]] = q.content
      if o%2!=0 and q.content=~/:/
        figart[o] = q.content
      else
        figart[figart[o-1]] = q.content
        figart.delete(o-1)
      end
      o+=1
    end
    column_charges = Array.new()
    @doc.css("[@id='ContentPlaceHolder1_LabelFullCase2']").css('th').each {|columnname| column_charges.push(columnname.content)}
    @doc.css("[@id='ContentPlaceHolder1_LabelFullCase2']").css('td').each_with_index {|val, i | figart[column_charges[i%4]] = val.content}
    figart.each do |key, value|
      @info[RENAME_COLUMNS[:info][key]] =
        if value.nil? or value.strip==''
          nil
        else
          value.strip
        end
    end
    if 'case_filed_date'.in? @info
      month_i, day_i, year_i  = @info['case_filed_date'].split('/')
      @info['case_filed_date'] = "#{year_i}-#{month_i}-#{day_i}"
    end
  end

  def get_judgement
    judgement_panel = @doc.css('[@id="ContentPlaceHolder1_PanelSection2"]')[0]
    return if judgement_panel.nil?
    return if judgement_panel.css('.detailsCaption')[0].content!='Judgments'

    judgement = {}
    judgement_panel.css('.detailsSection').each_with_index do |section, i|
      if i%2==0

        figart = {}
        o=0
        section.css('td').each do |q|
          if o%2==0
            figart[o] = q.content
          else
            figart[figart[o-1]] = q.content
            figart.delete(o-1)
          end
          o+=1
        end

        figart.each do |key, value|
          judgement[RENAME_COLUMNS[:judgement][key]] = value.strip
        end
        judgement.delete(nil)
      else
        column_values = section.css('.standardRow')[0]
        if !column_values.nil?
          judgement[:fee_amount] = column_values.css('td')[2].content
        end

        @judgements.push(judgement)
        judgement = {}
      end
    end

  end

  def get_action_table
    column_name = Array.new()
    action = Array.new()
    action_panel = @doc.css('[@id="ContentPlaceHolder1_PanelSection5"]')[0]
    return if action_panel.nil?
    action_panel.css('tr')[0].css('th').each {|q| column_name.push(q.content)}
    action_panel.css('tr')[1..].each do |line|
      action.push({})
      @activities.push({})

      line.css('td').each_with_index do |column, o|
        action[-1][column_name[o]] = column.content.strip
      end
      link_on_doc = line.css('td')[6].css('a')[0]
      unless link_on_doc.nil?
        action[-1][:activity_pdf] = "https://www2.greenvillecounty.org/SCJD/PublicIndex" + link_on_doc['href'][1..]
      end
    end
    @activities.each_index do |i|
      RENAME_COLUMNS[:activities].each do |string_on_site, string_in_db|
        @activities[i][string_in_db] = action[i][string_on_site]
      end
      if @activities[i][:activity_date]!=''
        month, day, year = @activities[i][:activity_date].split('-')[0].split('/')
        @activities[i][:activity_date] = "#{year}-#{month}-#{day}"
      end
      @activities[i][:case_id] = @info['case_id']
    end

  end

  def get_party

    column_name = Array.new()
    lawyers = Array.new()
    @doc.css('[@id="ContentPlaceHolder1_PanelSection1"]').css('tr')[0].css('th').each {|q| column_name.push(q.content)}
    @doc.css('[@id="ContentPlaceHolder1_PanelSection1"]').css('tr')[1..].each do |line|
      lawyers.push({})
      column_values = line.css('td')
      lawyers[-1][:party_name] = column_values[0].content
      address = column_values[1].content.strip
      lawyers[-1][:party_type] = column_values[5].content

      lawyers[-1][:is_lawyer] =
        if lawyers[-1][:party_type].include?('Attorney')
          1
        else
          0
        end

      lawyers[-1][:party_address] =
        if address.strip==''
          nil
        else
          address
        end


      state_zip = address.scan(/ [A-Z]{2} \d{4,5}\-?\d+/)[0]
      lawyers[-1][:party_state], lawyers[-1][:party_zip] = state_zip.strip.split(' ') if !state_zip.nil?

    end

    @party = lawyers
  end

end

#
# def check_parser
#   file = File.open('/Users/Magusch/RubymineProjects/Hamster/projects/project_0067_greenvile_county/lib/test/case_j1.html')
#   file_data = file.read
#
#   file.close
#
#   q = Parser.new file_data
#
# end