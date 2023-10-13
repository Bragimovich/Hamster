# frozen_string_literal: true

require_relative 'matching_words/match_db_models'
module UnexpectedTasks
  module Congress
    class MatchingWords

      def self.run(**options)
        p 'START'
        match_table = MatchTable.new()
        words = match_table.words_for_matching
        p words
        match_table.match_words(words)



      end
    end


    class MatchTable

      def initialize(table_name=:congress_record, text_column='clean_text', limit = 10)
        @table_name = table_name
        @text_column = text_column
        @limit = limit
      end


      def match_words(words)
        assert 'must be Hash={word_id:word}' if words.class!=Hash
        words = words_for_matching if words.nil? or words.empty?
        updated_at_days = 35

        words.each do |word_id, word|
          p word
          existing_ids = WordsMatched.where(word_id:word_id).map { |row| row[:matched_row_id] }  # Select where article_id and word_id in matched

          page = 0
          loop do
            matched_rows = []
            p page
            offset = page * @limit
            db_rows = db_models[@table_name.to_sym].where("date>'#{Date.today()-updated_at_days}'").where.not(id:existing_ids).where("#{@text_column} like '%#{word}%'").limit(@limit).offset(offset)
            db_rows.each do |row|
              matched_rows.push({
                                  word_id: word_id, matched_row_id: row[:id], table_name: @table_name.to_s
                                })
            end

            WordsMatched.insert_all(matched_rows) if !matched_rows.empty?
            break if db_rows.length<@limit
            page +=1
          end
        end
      end

      def words_for_matching
        matching_words = {}
        WordsForMatching.where(closed:0).map { |word| matching_words[word[:id]] = word[:word] }
        matching_words
      end

      private
      def db_models
        {congress_record: CongressionalRecordJournals, congress_legitimation: CongressionalLegislationTexts}
      end
    end

  end
end
