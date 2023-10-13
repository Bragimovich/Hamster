# frozen_string_literal: true

module QuArray
  class << self
    def quotation_marks
      '"“”'
    end

    def quotation_opening_marks
      '"“'
    end

    def quotation_closing_marks
      '"”'
    end

    def near_verbs
      %w[called cited meet]
    end

    def near_nouns
      %w[[aA]ttorney [cC]andidate [cC]ongressman [mM]ayor [oO]wner]
    end

    def cites_verbs
      %W[added appointed asked called charged cited confirmed continued explained #{'had a message'} issued noted posted praised provided released reminded reported responded said state[ds] told quoted wrote].join('|')
    end

    def cites_verbs_extended
      self.cites_verbs + '|' + %w[applauded argues can concedes has is points said says stresses struggles warns with wonders writes].join('|')
    end

    def sources
      ['(?>[Aa]|[Tt]he)(?> [a-zA-Z.]+)? (?>report|petition)', 'CBS Chicago', 'IPI'].join('|')
    end

    def person_name_prefixes
      %W[Dr #{'(?>[sS]tate )?Rep'} Sgt].join('|')
    end

    def person_name
      "(?>(?>(?>#{self.person_name_prefixes})[.] )?(?>[A-Z]'|-?[A-Z][a-z]+)|(?>[A-Z][.])+)+(?> +(?>(?>[A-Z]'|-?[A-Z][a-z]+)|(?>[A-Z][.])+)+(?> attorney|of)?)*"
    end

    def cite_after_person
      "(#{self.person_name}|#{self.sources}|\\b[sS]?[hH]e\\b)(?>,.+,)?[\\s ](?>was[\\s ])?(?>#{self.cites_verbs}).*[.,!?]?[\\s ]CITE"
    end

    def cite_inner_person
      "[\\s ](?>#{self.cites_verbs})(?>,.+,)?[\\s ](?>(?>[a-zA-Z0-9])+[\\s ])*?(#{self.person_name}|#{self.sources}|\\bs?he\\b)|[\\s ](#{self.person_name}|#{self.sources}|\\bs?he\\b)(?>,.+,)?[\\s ](?>(?>[a-zA-Z0-9])+[\\s ])*?(?>#{self.cites_verbs})[.]?"
    end

    def cite_before_vp
      "CITE[\\s ](?>#{self.cites_verbs})(?>,.+,)?[\\s ](?>(?>[a-zA-Z0-9])+[\\s ])*(#{self.person_name}|#{self.sources}|\\bs?he\\b)"
    end

    def cite_before_pv
      "CITE[\\s ](#{self.person_name}|#{self.sources}|\\bs?he\\b)(?>,.+,)?[\\s ](?>(?>[a-zA-Z0-9])+[\\s ])*(?>#{self.cites_verbs})"
    end
  end
end
