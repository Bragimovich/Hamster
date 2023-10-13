require 'nlp_pure/segmenting/default_sentence'

# Shortens the teaser to the given length.
class TeaserCorrector
  DEFAULT_MAX_SIZE = 600

  # Create a new TeaserCorrector
  # @param [String] teaser - text that may need to be shortened
  # @param [Integer] max_size - maximum allowed size of the teaser
  def initialize(teaser, max_size = DEFAULT_MAX_SIZE)
    @teaser = teaser.strip
    @max_size = max_size
  end

  # @return [String] shortened teaser
  def correct
    return @teaser unless correction_needed?

    @sentences = NlpPure::Segmenting::DefaultSentence.parse(@teaser)

    if first_sentence_is_too_long?
      @teaser = cut_first_sentence
    else
      @teaser = join_sentences_till_max_size
    end
    
    @teaser = replace_colon if colon_ending?
    @teaser
  end
  
  private

  def first_sentence_is_too_long?
    @sentences.first.size >= @max_size
  end

  def cut_first_sentence
    @new_sentence = ''
    words = @sentences.first.split(' ')

    words.each do |word|
      break if (@new_sentence.size + word.size) > @max_size

      @new_sentence = @new_sentence + ' ' + word
    end
    
    pop_small_words

    @new_sentence + '...'
  end
  
  def pop_small_words
    last_word = @new_sentence.split.last
    if last_word.size <= 3
      remove_last_word
      pop_small_words
    end
  end

  def join_sentences_till_max_size
    new_teaser = ''

    @sentences.each do |sentence|
      break if (new_teaser.size + sentence.size) > @max_size

      new_teaser = new_teaser + sentence
    end
    new_teaser
  end

  def correction_needed?
    too_long? || colon_ending?
  end

  def colon_ending?
    @teaser.last == ':'
  end

  def too_long?
    @teaser.size > @max_size
  end

  def replace_colon
    @teaser.gsub(/\:$/, '...')
  end

  def remove_last_word
    @new_sentence = @new_sentence.split(' ')[0...-1].join(' ')
  end

end
