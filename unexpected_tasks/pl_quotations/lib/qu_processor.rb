# frozen_string_literal: true

class QuProcessor
  def initialize(story)
    @story = story
  end

  def story_analysis
    preliminary_analysis

    additional_analysis

    { story: @paragraphs, possible_names: @possible_names, quotations: @quotations }
  end

  private

  def preliminary_analysis
    @paragraphs     = {}
    @possible_names = []

    @story.split("\n").each_with_index do |paragraph, index|
      @paragraphs[index]        ||= {}
      paragraph                 = paragraph.gsub(/ /, ' ').strip
      @paragraphs[index][:text] = paragraph

      origin         = nil
      has_origin     = :possibly
      quotations     = paragraph.scan(QuRE.cites_both_quotes).flatten.compact.map(&:strip)
      quotation_type = nil

      if paragraph.empty?
        quotation_type                          = :none
        @paragraphs[index - 1][:quotation_type] = :whole if index.positive? && @paragraphs[index - 1][:quotation_type] == :start
        @paragraphs[index - 1][:quotation_type] = :end if index > 1 && @paragraphs[index - 1][:quotation_type] == :continue
      else
        if quotations.empty?
          full_names     = paragraph.gsub(QuRE.forbidden_words, '').scan(QuRE.possible_name).flatten.compact.delete_if { |name| name.match?(QuRE.not_a_names) }
          quotations     = [paragraph] if paragraph[0].match?(QuRE.quotes_match)
          quotation_type =
            if paragraph[0].match?(QuRE.quotes_match) && (index.zero? || %i[none whole].include?(@paragraphs[index - 1][:quotation_type]))
              :start
            elsif !paragraph[0].match?(QuRE.quotes_match)
              @paragraphs[index - 1][:quotation_type] = :whole if index.positive? && @paragraphs[index - 1][:quotation_type] == :start
              @paragraphs[index - 1][:quotation_type] = :end if index > 1 && @paragraphs[index - 1][:quotation_type] == :continue
              :none
            else
              :continue
            end
          has_origin     = :none
        else
          quotations = quotations.map do |quotation|
            if quotation.match?(%r{^.+".+$})
              quotation.match(%r{(^.+").+(".+$)})
              quotation.gsub(%r{(^.+").+(".+$)}, "#{$1}\n#{$2}").split("\n").map(&:strip)
            else
              quotation
            end
          end.flatten.compact.map(&:strip)

          text = paragraph
          quotations.each { |quotation| text = text.sub(quotation, 'CITE') }
          full_names = text.gsub(QuRE.forbidden_words, '').scan(QuRE.possible_name).flatten.compact.delete_if { |name| name.match?(QuRE.not_a_names) }
          origin     =
            (text.match?(%r{CITE.+CITE}) ? text.scan(QuRE.cite_inner_persons) : text.scan(QuRE.cite_persons))
              .flatten.compact.map { |el| el.gsub(QuRE.forbidden_words, '') }
              .delete_if { |el| el.empty? }.join(', ').strip.gsub(/[.,]$/, '').split(' ')
              .compact.join(' ')
          has_origin = origin.nil? || origin.empty? || origin.match?(/s?he/i) ? :possibly : :yes
        end

        @paragraphs[index][:quotations] = quotations.join(' ') unless quotations.join(' ').size <= 12
        @paragraphs[index][:origin]     = origin unless origin.nil?
        @possible_names << full_names

        if @paragraphs[index][:quotations] && (origin&.empty? || origin&.match?(/s?he/i))
          @paragraphs[index][:quotations] = quotations.join(' ') if (paragraph.size / 2) < quotations.join(' ').size
        end

        quotation_type =
          if !@paragraphs[index][:quotations]
            :none
          elsif paragraph[0].match?(QuRE.quotes_match) &&
            (index.zero? || index.positive? && %i[none inner partly].include?(@paragraphs[index - 1][:quotation_type])) &&
            (index < @story.split("\n").size - 1) && @paragraphs[index][:quotations]&.size == paragraph.size
            :start
          elsif paragraph[0].match?(QuRE.quotes_match) &&
            index.positive? && %i[continue start].include?(@paragraphs[index - 1][:quotation_type]) &&
            (index < @story.split("\n").size - 1) && @paragraphs[index][:quotations].size > (paragraph.size / 2)
            :continue
          elsif paragraph[0].match?(QuRE.quotes_match) && (index == @story.split("\n").size - 1) &&
            %i[continue start].include?(@paragraphs[index - 1][:quotation_type])
            :end
          elsif (index.zero? || index.positive? && !%i[continue start].include?(@paragraphs[index - 1])) &&
            @paragraphs[index][:quotations]&.size == paragraph.size
            :whole
          elsif (index.zero? || index.positive? && !%i[continue start].include?(@paragraphs[index - 1])) &&
            paragraph[0].match?(QuRE.quotes_match) && (paragraph.strip[-1].match?(QuRE.quotes_match) || quotations.size == 2)
            :inner
          else
            :partly
          end if quotation_type.nil?
      end

      @paragraphs[index][:has_origin]     = %i[inner partly].include?(quotation_type) ? has_origin : :none
      @paragraphs[index][:quotation_type] = quotation_type
    end

    @possible_names = @possible_names.flatten.compact.uniq
  end

  def additional_analysis
    @quotations = []
    @quotations << { text: [], place: [] }
    @paragraphs.each do |index, paragraph|
      if %i[continue start].include?(paragraph[:quotation_type]) || @paragraphs[@paragraphs.size - 1] != paragraph &&
        paragraph[:quotation_type] == :inner && !%i[inner partly none].include?(@paragraphs[index + 1][:quotation_type])
        @quotations.last[:text] << paragraph[:quotations]
        @quotations.last[:place] << index
        @quotations.last[:origin] = paragraph[:origin] unless paragraph[:has_origin] == :none
      elsif paragraph[:quotation_type] == :end || paragraph[:quotation_type] == :whole &&
        @paragraphs[0] != paragraph && @paragraphs[index - 1] == :inner
        @quotations.last[:text] << paragraph[:quotations]
        @quotations.last[:place] << index
        @quotations.last[:type]   = :multi
        @quotations.last[:origin] = paragraph[:origin] if paragraph[:has_origin] != :none || @quotations.last[:origin].nil?
        @quotations << { text: [], place: [], origin: nil }
      elsif paragraph[:quotation_type] == :partly || @paragraphs[@paragraphs.size - 1] != paragraph &&
        paragraph[:quotation_type] == :inner && !%i[:start :whole].include?(@paragraphs[index + 1])
        @quotations.last[:text] << paragraph[:quotations]
        @quotations.last[:place]  = index
        @quotations.last[:type]   = paragraph[:quotation_type]
        @quotations.last[:origin] = paragraph[:origin]
        @quotations << { text: [], place: [] }
      end
    end

    @quotations = @quotations.map do |quotation|
      { text:   (quotation[:text].empty? ? nil : quotation[:text].join("\n")),
        place:  quotation[:place].is_a?(Integer) ? quotation[:place] : [quotation[:place].first, quotation[:place].last],
        type:   quotation[:type],
        origin: quotation[:origin]
      } unless quotation[:text].empty?
    end.compact

    @quotations.each do |quotation|
      if quotation[:origin].empty? || quotation[:origin].match?(%r[\bs?he\b]i)
        names     = []
        index     = quotation[:place].is_a?(Integer) ? quotation[:place] : quotation[:place].first
        calculate = -> do
          if !index.negative?
            %i[inner partly].include?(quotation[:type]) ? 0 : 1
          else
            index + 1
          end
        end

        step = calculate[]
        while names.empty? && !(index - step).negative? do
          text  = @paragraphs[index - step][:text].gsub(QuRE.forbidden_words, '')
          text  = text.gsub(%r[[#{QuArray.quotation_opening_marks}]([^#{QuArray.quotation_marks}]+$|.+?[#{QuArray.quotation_closing_marks}])], '') if %i[inner partly].include?(quotation[:type])
          names = text.scan(QuRE.possible_speaker)
          names = [] if names.join(' ').match?(QuRE.not_a_names)
          step  += 1
        end

        step = calculate[]
        while names.empty? && !(index - step).negative? do
          text  = @paragraphs[index - step][:text].gsub(QuRE.forbidden_words, '')
          text  = text.gsub(%r[#{QuRE.opening_quotes}.+?#{QuRE.closing_quotes}], '') if %i[inner partly].include?(quotation[:type])
          names = text.scan(QuRE.capitalized)
          step  += 1
        end

        names = names.flatten.compact.uniq

        @possible_names = @possible_names.flatten.compact.uniq

        found = false

        if names.size == 1 && names.first.split(' ').size == 1
          names = @possible_names.select { |name| name.match?(names.first) }.flatten.compact.uniq
          found = true
        elsif names.size == 1 && names.first.split(' ').size > 1
          found = true
        elsif names.size > 1
          @possible_names.each do |possible_name|
            names.each do |name|
              if /#{name}/.match?(possible_name)
                names = possible_name
                found = true
              end
              break if found
            end

            break if found
          end
        end

        quotation[:possible_origin] = quotation[:origin].empty? && !found ? [''] : [names].flatten
      else
        possible_origin             = @possible_names.select { |name| name.match?(%r[#{quotation[:origin].split(', ').join('|')}]) }.flatten.compact.uniq
        quotation[:possible_origin] = possible_origin.empty? ? [quotation[:origin]] : possible_origin
      end

      quotation[:possible_origin] =
        quotation[:possible_origin].first.split(', ') if quotation[:possible_origin].size == 1 && quotation[:possible_origin].first.split(', ').size == 2
      quotation[:possible_origin] =
        if quotation[:possible_origin].size == 2 &&
          quotation[:possible_origin].first&.match?(quotation[:possible_origin]&.last) ||
          quotation[:possible_origin].last&.match?(quotation[:possible_origin]&.first)
          quotation[:possible_origin].max { |a, b| a.size <=> b.size }
        else
          quotation[:possible_origin].join(', ')
        end
      quotation[:probably_wrong]  =
        !quotation[:possible_origin].empty? &&
          (quotation[:origin].empty? || quotation[:origin].match?(/\bs?he\b/i) || quotation[:text].split(' ').size <= 12)
    end
  end
end
