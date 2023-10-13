# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    super
  end

  def date_format(text)
    return unless text
    existing_format = '%m/%d/%Y' 
    existing_format = '%m/%d/%y' if text.length < 10
    date =  Date.strptime(text, existing_format) rescue nil
    
    date = date.strftime('%Y-%m-%d').to_s if date
  end
  
end
