# frozen_string_literal: true

module QuRE
  class << self
    def possible_speaker
      %r[(#{QuArray.person_name}):|(#{QuArray.person_name})(?> \(.+\))?(?>,.+?,)?[\s ](?>#{QuArray.cites_verbs_extended})|(?>#{QuArray.cites_verbs})(?>,.+?,)?[\s ](#{QuArray.person_name})\b]
    end

    def cite_persons
      %r[#{QuArray.cite_after_person}|#{QuArray.cite_before_vp}|#{QuArray.cite_before_pv}]
    end

    def cite_inner_persons
      %r[#{QuArray.cite_inner_person}]
    end

    def quotes_match
      %r[["“”]]
    end

    def opening_quotes
      %r[["“]]
    end

    def closing_quotes
      %r[["”\n]]
    end

    def strange_quotes_match
      %r[[“«»”]]
    end

    def cites_strange_quotes
      %r[(?<=[“])([-.,!?’'"\[\]()\s\w]+)]
    end

    def cites_normal_quotes
      %r["([-.,!?’'\[\]()\s\w]+)"]
    end

    def cites_both_quotes
      %r[(?>(“[^”]+[”"](?>[^“”\n]+(?=[”"])(?!\n[“]))*)(?!\n[“]))|(“[^”\n]+)|("[^”"\n]+”)|("[^"\n]+")|("[^"\n]+)]
    end

    def not_a_names
      %r[\b(?>#{%w[academy association better county dupage government group journal like meet office policy school vice west].join('|')})\b]i
    end

    def forbidden_words
      %r[#{'(?>(?>the|a) U[.]S[.])|\b(?>' + %w[After Although And? Another As At But Even For He(?>re?)? I[fnt]? Like My New Now On Our She Team That The(?>re)? This Today Unlike What When While Why With].join('|')})\b]
    end

    def possible_name
      # %r[(?<![(-])(?<!the )(?>#{QuArray.person_name_prefixes}[.] )?(\b(?>[A-Z][-'a-z]+|(?>[A-Z][.])+)+(?> +(?>[A-Z][-'a-z]+|(?>[A-Z][.])+)+)+)]
      %r[(?<![(-])(?<!the )#{QuArray.person_name}]
    end

    def capitalized
      %r{[A-Z][-'a-z]+}
    end
  end
end
