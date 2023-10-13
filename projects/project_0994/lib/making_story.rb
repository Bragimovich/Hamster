# frozen_string_literal: true



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
  q=0
  loop do
    p q
    q+=1
    records = CongressionalRecordJournals.where(dirty:0).where(clean_text: nil).first(500)

    records.each do |rec|

      paragraph = "\n  "
      text = rec.text.split('[www.gpo.gov]')[1] # delete_first_row
      #         text like '%....%' and text like '%----%'        text like '%....%' and text like '%----%'
      dependence_par_to_length = Float(text.split(paragraph).length)/Float(text.length) # dependence paragraphs to length
      p dependence_par_to_length
      next if dependence_par_to_length*100>4
      #text = text.gsub(/\n\[?.*\]\n/, ' ').gsub(/\b \n\b/, '').gsub("\n     ", "")
      clean_text = text.gsub(/\n\n\[?.*\]\n/, ' ').gsub(/\b \n\b/, " ").gsub(/ \n\s*(?=[a-z])/, " ").gsub(/\n     (?=\w)/, "").gsub(/(?<=.) \n\b/, " ") #for delete pagination #not check
      p rec.link
      rec.clean_text = clean_text.strip
      rec.save
    end
    break if records.to_a.length<500
  end
end


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


def get_congressmens

  CongressionalRecordJournals


end