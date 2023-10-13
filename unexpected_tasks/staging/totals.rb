require_relative 'models/staging_courts'
require_relative 'models/staging_cases'
require_relative 'models/staging_judges'
require_relative 'models/staging_activities'
require_relative 'models/analys_litigation_totals'
require_relative 'sql/totals_sql'
require_relative 'tools/message_send'
require_relative 'tools/add_commas'

module UnexpectedTasks
  module Staging
    class Totals
      ##### DICTIONARY OF VARIABLES
      # tc_now                          -   Total cases now
      # tc_query                        -   Total cases query
      #
      # tc_p1_now                       -   Total cases Phase 1 now
      # tc_p1_query                     -   Total cases Phase 1 query
      # tc_p1_change                    -   Total cases Phase 1 change
      #
      # tc_p2_now                       -   Total cases Phase 2 now
      # tc_p2_query                     -   Total cases Phase 2 query
      # tc_p2_change                    -   Total cases Phase 2 change
      #
      # tc_2020_now                     -   Total cases from 2020 now
      # tc_2020_query                   -   Total cases from 2020 query
      # tc_2020_change                  -   Total cases from 2020 change
      #
      # tc_2020_p1_now                  -   Total cases from 2020 Phase 1 now
      # tc_2020_p1_query                -   Total cases from 2020 Phase 1 query
      # tc_2020_p1_change               -   Total cases from 2020 Phase 1 change
      #
      # tc_2020_p2_now                  -   Total cases from 2020 Phase 2 now
      # tc_2020_p2_query                -   Total cases from 2020 Phase 2 query
      # tc_2020_p2_change               -   Total cases from 2020 Phase 2 change
      #
      # tc_wv_now                       -   Total cases West Virginia now
      # tc_wv_query                     -   Total cases West Virginia query
      # tc_wv_change                    -   Total cases West Virginia change
      #
      # tc_mo_now                       -   Total cases Missouri now
      # tc_mo_query                     -   Total cases Missouri query
      # tc_mo_change                    -   Total cases Missouri change
      #
      # tc_la_now                       -   Total cases Louisiana now
      # tc_la_query                     -   Total cases Louisiana query
      # tc_la_change                    -   Total cases Louisiana change
      #
      # tc_f3m_now                      -   Total cases filed in last 3 months now
      # tc_f3m_query                    -   Total cases filed in last 3 months query
      #
      # tuc_2020_now                    -   Total uncategorized cases 2020+ now
      # tuc_2020_query                  -   Total uncategorized cases 2020+ query
      # tuc_2020_change                 -   Total uncategorized cases 2020+ change
      #
      # tuc_2020_pdf_now                -   Total uncategorized cases 2020+ with pdf now
      # tuc_2020_pdf_query              -   Total uncategorized cases 2020+ with pdf query
      # tuc_2020_pdf_change             -   Total uncategorized cases 2020+ with pdf change
      #
      # tuc_2020_pdf_p1_now             -   Total uncategorized cases 2020+ with pdf Phase 1 now
      # tuc_2020_pdf_p1_query           -   Total uncategorized cases 2020+ with pdf Phase 1 query
      # tuc_2020_pdf_p1_change          -   Total uncategorized cases 2020+ with pdf Phase 1 change
      #
      # tuc_2020_pdf_p2_now             -   Total uncategorized cases 2020+ with pdf Phase 2 now
      # tuc_2020_pdf_p2_query           -   Total uncategorized cases 2020+ with pdf Phase 2 query
      # tuc_2020_pdf_p2_change          -   Total uncategorized cases 2020+ with pdf Phase 2 change
      #
      # tuc_pdf_not_tried_now           -   Total uncategorized cases not tried now
      # tuc_pdf_not_tried_query         -   Total uncategorized cases not tried query
      # tuc_pdf_not_tried_change        -   Total uncategorized cases not tried change
      #
      # tuc_not_pdf_now                 -   Total uncategorized cases do not have pdf now
      # tuc_not_pdf_query               -   Total uncategorized cases do not have pdf query
      # tuc_not_pdf_change              -   Total uncategorized cases do not have pdf change
      #
      # tuc_not_pdf_rt_now              -   Total uncategorized cases do not have pdf with raw type now
      # tuc_not_pdf_rt_query            -   Total uncategorized cases do not have pdf with raw type query
      # tuc_not_pdf_rt_change           -   Total uncategorized cases do not have pdf with raw type change
      #
      # tuc_2020_not_pdf_now            -   Total uncategorized cases 2020+ do not have pdf now
      # tuc_2020_not_pdf_query          -   Total uncategorized cases 2020+ do not have pdf query
      # tuc_2020_not_pdf_change         -   Total uncategorized cases 2020+ do not have pdf change
      #
      # tuc_2020_not_pdf_rt_now         -   Total uncategorized cases 2020+ do not have pdf with raw type now
      # tuc_2020_not_pdf_rt_query       -   Total uncategorized cases 2020+ do not have pdf with raw type query
      # tuc_2020_not_pdf_rt_change      -   Total uncategorized cases 2020+ do not have pdf with raw type change
      #
      # tuc_2020_as_now                 -   Total uncategorized cases from appeals and supreme courts 2020+ now
      # tuc_2020_as_query               -   Total uncategorized cases from appeals and supreme courts 2020+ query
      # tuc_2020_as_change              -   Total uncategorized cases from appeals and supreme courts 2020+ change
      #
      # tuc_3m_now                      -   Total uncategorized cases added in past 3 month now
      # tuc_3m_query                    -   Total uncategorized cases added in past 3 month query
      # tuc_3m_change                   -   Total uncategorized cases added in past 3 month change
      #
      # tuc_either_now                  -   Total uncategorized cases either raw type, desc, text now
      # tuc_either_query                -   Total uncategorized cases either raw type, desc, text query
      # tuc_either_change               -   Total uncategorized cases either raw type, desc, text change
      #
      # tco_p2_now                      -   Total Phase II courts now
      # tco_p2_query                    -   Total Phase II courts query
      # tco_p2_change                   -   Total Phase II courts change
      #
      # tco_p2_x_now                    -   Total Phase II courts x now
      # tco_p2_x_query                  -   Total Phase II courts x query
      # tco_p2_y_now                    -   Total Phase II courts y now
      # tco_p2_p_now                    -   Total Phase II courts percent now
      #
      # tco_p2_50_now                   -   Total Phase II courts id db with >= 50 cases now
      # tco_p2_50_query                 -   Total Phase II courts id db with >= 50 cases query
      # tco_p2_50_change                -   Total Phase II courts id db with >= 50 cases change
      #
      # tco_p2_not_scrap_now            -   Total Phase II courts that cannot be scraped now
      # tco_p2_not_scrap_query          -   Total Phase II courts that cannot be scraped query
      # tco_p2_not_scrap_change         -   Total Phase II courts that cannot be scraped change
      #
      # tj_p2_now                       -   Total Phase II court judges now
      # tj_p2_query                     -   Total Phase II court judges query
      # tj_p2_change                    -   Total Phase II court judges change
      #
      # tc_2020_p2_appeal_now           -   Total Phase II cases from appeals courts (2020+) now
      # tc_2020_p2_appeal_query         -   Total Phase II cases from appeals courts (2020+) query
      # tc_2020_p2_appeal_change        -   Total Phase II cases from appeals courts (2020+) change
      #
      # tc_2020_p2_supreme_now          -   Total Phase II cases from State or Federal Supreme courts (2020+) now
      # tc_2020_p2_supreme_query        -   Total Phase II cases from State or Federal Supreme courts (2020+) query
      # tc_2020_p2_supreme_change       -   Total Phase II cases from State or Federal Supreme courts (2020+) change
      #
      # tc_2020_p2_lower_now            -   Total Phase II cases from Appeals/Supreme courts that are matched to lower court cases (2020+) now
      # tc_2020_p2_lower_query          -   Total Phase II cases from Appeals/Supreme courts that are matched to lower court cases (2020+) query
      # tc_2020_p2_lower_change         -   Total Phase II cases from Appeals/Supreme courts that are matched to lower court cases (2020+) changes
      #
      # tc_p2_pdf_now                   -   Total Phase II cases with PDFs now
      # tc_p2_pdf_query                 -   Total Phase II cases with PDFs query
      # tc_p2_pdf_change                -   Total Phase II cases with PDFs change
      #
      # tc_p2_that_cat_now              -   Total Phase II cases that are categorized now
      # tc_p2_that_cat_query            -   Total Phase II cases that are categorized query
      # tc_p2_that_cat_change           -   Total Phase II cases that are categorized change
      #
      # tc_p2_lawyers_now               -   Total Phase II cases with lawyers now
      # tc_p2_lawyers_query             -   Total Phase II cases with lawyers query
      # tc_p2_lawyers_change            -   Total Phase II cases with lawyers change
      #
      # tc_p2_judges_now                -   Total Phase II cases with judges now
      # tc_p2_judges_query              -   Total Phase II cases with judges query
      # tc_p2_judges_change             -   Total Phase II cases with judges change
      #
      # tco_p1_damage_now               -   Total Phase I Courts with damage amounts now
      # tco_p1_damage_query             -   Total Phase I Courts with damage amounts query
      # tco_p1_damage_change            -   Total Phase I Courts with damage amounts change
      #
      # tc_p1_damage_now                -   Total Phase I Court cases with damage amounts now
      # tc_p1_damage_query              -   Total Phase I Court cases with damage amounts query
      # tc_p1_damage_change             -   Total Phase I Court cases with damage amounts change
      #
      # tco_p1_closed_now               -   Total Phase I Courts with "Closed" cases now
      # tco_p1_closed_query             -   Total Phase I Courts with "Closed" cases query
      # tco_p1_closed_change            -   Total Phase I Courts with "Closed" cases change
      #
      # tco_p1_act_pdf_now              -   Total Phase I Courts with PDFs on activities now
      # tco_p1_act_pdf_query            -   Total Phase I Courts with PDFs on activities query
      # tco_p1_act_pdf_change           -   Total Phase I Courts with PDFs on activities change
      #
      # ta_now                          -   Total activities now
      # ta_query                        -   Total activities query
      # ta_change                       -   Total activities change
      #
      # ta_p1_now                       -   Total Phase I court activities now
      # ta_p1_query                     -   Total Phase I court activities query
      # ta_p1_change                    -   Total Phase I court activities change
      #
      # ta_p2_now                       -   Total Phase II court activities now
      # ta_p2_query                     -   Total Phase II court activities query
      # ta_p2_change                    -   Total Phase II court activities change
      #
      #####
      def self.run(**options)
        title = 'Staging | Totals'
        test_channel = 'C03RTH1G6P3'
        litigation_channel = 'C03EMT3LS2D'
        igor_sas = 'U02KWJ3PQKB'
        john_putz = 'U02TSHJ0E'
        rylan_klatt = 'U01AQ8CC60Z'
        today = Date.today
        today_3m = today - 3.month
        tc_now = StagingCases.connection.execute(tc_query).to_a[0][0]
        Hamster.logger.info "tc_query - Ok."
        tc_p1_now = StagingCases.connection.execute(tc_p1_query).to_a[0][0]
        Hamster.logger.info "tc_p1_query - Ok."
        tc_p2_now = StagingCases.connection.execute(tc_p2_query).to_a[0][0]
        Hamster.logger.info "tc_p2_query - Ok."
        tc_2020_now = StagingCases.connection.execute(tc_2020_query).to_a[0][0]
        Hamster.logger.info "tc_2020_query - Ok."
        tc_2020_p1_now = StagingCases.connection.execute(tc_2020_p1_query).to_a[0][0]
        Hamster.logger.info "tc_2020_p1_query - Ok."
        tc_2020_p2_now = StagingCases.connection.execute(tc_2020_p2_query).to_a[0][0]
        Hamster.logger.info "tc_2020_p2_query - Ok."
        tc_wv_now = StagingCases.connection.execute(tc_wv_query).to_a[0][0]
        Hamster.logger.info "tc_wv_query - Ok."
        tc_mo_now = StagingCases.connection.execute(tc_mo_query).to_a[0][0]
        Hamster.logger.info "tc_mo_query - Ok."
        tc_la_now = StagingCases.connection.execute(tc_la_query).to_a[0][0]
        Hamster.logger.info "tc_la_query - Ok."
        tc_f3m_now = StagingCases.connection.execute(tc_f3m_query(today_3m)).to_a[0][0]
        Hamster.logger.info "tc_f3m_query - Ok."
        tuc_2020_now = StagingCases.connection.execute(tuc_2020_query).to_a[0][0]
        Hamster.logger.info "tuc_2020_query - Ok."
        tuc_2020_pdf_now = StagingCases.connection.execute(tuc_2020_pdf_query).to_a[0][0]
        Hamster.logger.info "tuc_2020_pdf_query - Ok."
        tuc_2020_pdf_p1_now = StagingCases.connection.execute(tuc_2020_pdf_p1_query).to_a[0][0]
        Hamster.logger.info "tuc_2020_pdf_p1_query - Ok."
        tuc_2020_pdf_p2_now = StagingCases.connection.execute(tuc_2020_pdf_p2_query).to_a[0][0]
        Hamster.logger.info "tuc_2020_pdf_p2_query - Ok."
        tuc_pdf_not_tried_now = 0
        tuc_not_pdf_now = StagingCases.connection.execute(tuc_not_pdf_query).to_a[0][0]
        Hamster.logger.info "tuc_not_pdf_query - Ok."
        tuc_not_pdf_rt_now = StagingCases.connection.execute(tuc_not_pdf_rt_query).to_a[0][0]
        Hamster.logger.info "tuc_not_pdf_rt_query - Ok."
        tuc_2020_not_pdf_now = StagingCases.connection.execute(tuc_2020_not_pdf_query).to_a[0][0]
        Hamster.logger.info "tuc_2020_not_pdf_query - Ok."
        tuc_2020_not_pdf_rt_now = StagingCases.connection.execute(tuc_2020_not_pdf_rt_query).to_a[0][0]
        Hamster.logger.info "tuc_2020_not_pdf_rt_query - Ok."
        tuc_2020_as_now = StagingCases.connection.execute(tuc_2020_as_query).to_a[0][0]
        Hamster.logger.info "tuc_2020_as_query - Ok."
        tuc_3m_now = StagingCases.connection.execute(tuc_3m_query).to_a[0][0]
        Hamster.logger.info "tuc_3m_query - Ok."
        tuc_either_now = StagingCases.connection.execute(tuc_either_query).to_a[0][0]
        Hamster.logger.info "tuc_either_query - Ok."
        tco_p2_now = StagingCourts.connection.execute(tco_p2_query).to_a[0][0]
        Hamster.logger.info "tco_p2_query - Ok."
        tco_p2_x_now = StagingCourts.connection.execute(tco_p2_x_query).to_a[0][0]
        Hamster.logger.info "tco_p2_x_query - Ok."
        tco_p2_y_now = 136
        tco_p2_p_now = (tco_p2_x_now.to_f / tco_p2_y_now * 100).round(2)
        tco_p2_50_now = StagingCourts.connection.execute(tco_p2_50_query).to_a[0][0]
        Hamster.logger.info "tco_p2_50_query - Ok."
        tco_p2_not_scrap_now = 36
        tj_p2_now = StagingJudges.connection.execute(tj_p2_query).to_a[0][0]
        Hamster.logger.info "tj_p2_query - Ok."
        tc_2020_p2_appeal_now = StagingCases.connection.execute(tc_2020_p2_appeal_query).to_a[0][0]
        Hamster.logger.info "tc_2020_p2_appeal_query - Ok."
        tc_2020_p2_supreme_now = StagingCases.connection.execute(tc_2020_p2_supreme_query).to_a[0][0]
        Hamster.logger.info "tc_2020_p2_supreme_query - Ok."
        tc_2020_p2_lower_now = 0
        tc_p2_pdf_now = StagingCases.connection.execute(tc_p2_pdf_query).to_a[0][0]
        Hamster.logger.info "tc_p2_pdf_query - Ok."
        tc_p2_that_cat_now = StagingCases.connection.execute(tc_p2_that_cat_query).to_a[0][0]
        Hamster.logger.info "tc_p2_that_cat_query - Ok."
        tc_p2_lawyers_now = StagingCases.connection.execute(tc_p2_lawyers_query).to_a[0][0]
        Hamster.logger.info "tc_p2_lawyers_query - Ok."
        tc_p2_judges_now = StagingCases.connection.execute(tc_p2_judges_query).to_a[0][0]
        Hamster.logger.info "tc_p2_judges_query - Ok."
        tco_p1_damage_now = StagingCourts.connection.execute(tco_p1_damage_query).to_a[0][0]
        Hamster.logger.info "tco_p1_damage_query - Ok."
        tc_p1_damage_now = StagingCases.connection.execute(tc_p1_damage_query).to_a[0][0]
        Hamster.logger.info "tc_p1_damage_query - Ok."
        tco_p1_closed_now = StagingCourts.connection.execute(tco_p1_closed_query).to_a[0][0]
        Hamster.logger.info "tco_p1_closed_query - Ok."
        tco_p1_act_pdf_now = StagingCourts.connection.execute(tco_p1_act_pdf_query).to_a[0][0]
        Hamster.logger.info "tco_p1_act_pdf_query - Ok."
        total_p1_courts = StagingCourts.connection.execute(total_p1_courts_query).to_a[0][0]
        Hamster.logger.info "total_p1_courts_query - Ok."
        ta_now = StagingActivities.connection.execute(ta_query).to_a[0][0]
        Hamster.logger.info "ta_query - Ok."
        ta_p1_now = StagingActivities.connection.execute(ta_p1_query).to_a[0][0]
        Hamster.logger.info "ta_p1_query - Ok."
        ta_p2_now = StagingActivities.connection.execute(ta_p2_query).to_a[0][0]
        Hamster.logger.info "ta_p2_query - Ok."
        changes = AnalysLitigationTotals.where("date = '#{today - 14.day}'")
        Hamster.logger.info "changes_query - Ok."
        tc_p1_change = changes.blank? ? 0 : tc_p1_now - changes[0]['tc_p1']
        tc_p2_change = changes.blank? ? 0 : tc_p2_now - changes[0]['tc_p2']
        tc_2020_p1_change = changes.blank? ? 0 : tc_2020_p1_now - changes[0]['tc_2020_p1']
        tc_2020_p2_change = changes.blank? ? 0 : tc_2020_p2_now - changes[0]['tc_2020_p2']
        tc_wv_change = changes.blank? ? 0 : tc_wv_now - changes[0]['tc_wv']
        tc_mo_change = changes.blank? ? 0 : tc_mo_now - changes[0]['tc_mo']
        tc_la_change = changes.blank? ? 0 : tc_la_now - changes[0]['tc_la']
        tuc_2020_change = changes.blank? ? 0 : tuc_2020_now - changes[0]['tuc_2020']
        tuc_2020_pdf_change = changes.blank? ? 0 : tuc_2020_pdf_now - changes[0]['tuc_2020_pdf']
        tuc_2020_pdf_p1_change = changes.blank? ? 0 : tuc_2020_pdf_p1_now - changes[0]['tuc_2020_pdf_p1']
        tuc_2020_pdf_p2_change = changes.blank? ? 0 : tuc_2020_pdf_p2_now - changes[0]['tuc_2020_pdf_p2']
        tuc_pdf_not_tried_change = changes.blank? ? 0 : tuc_pdf_not_tried_now - changes[0]['tuc_pdf_not_tried']
        tuc_not_pdf_change = changes.blank? ? 0 : tuc_not_pdf_now - changes[0]['tuc_not_pdf']
        tuc_2020_not_pdf_change = changes.blank? ? 0 : tuc_2020_not_pdf_now - changes[0]['tuc_2020_not_pdf']
        tuc_2020_as_change = changes.blank? ? 0 : tuc_2020_as_now - changes[0]['tuc_2020_as']
        tuc_3m_change = changes.blank? ? 0 : tuc_3m_now - changes[0]['tuc_3m']
        tuc_either_change = changes.blank? ? 0 : tuc_either_now - changes[0]['tuc_either']
        tco_p2_change = changes.blank? ? 0 : tco_p2_now - changes[0]['tco_p2']
        tco_p2_50_change = changes.blank? ? 0 : tco_p2_50_now - changes[0]['tco_p2_50']
        tco_p2_not_scrap_change = changes.blank? ? 0 : tco_p2_not_scrap_now - changes[0]['tco_p2_not_scrap']
        tj_p2_change = changes.blank? ? 0 : tj_p2_now - changes[0]['tj_p2']
        tc_2020_p2_appeal_change = changes.blank? ? 0 : tc_2020_p2_appeal_now - changes[0]['tc_2020_p2_appeal']
        tc_2020_p2_supreme_change = changes.blank? ? 0 : tc_2020_p2_supreme_now - changes[0]['tc_2020_p2_supreme']
        tc_2020_p2_lower_change = changes.blank? ? 0 : tc_2020_p2_lower_now - changes[0]['tc_2020_p2_lower']
        tc_p2_pdf_change = changes.blank? ? 0 : tc_p2_pdf_now - changes[0]['tc_p2_pdf']
        tc_p2_that_cat_change = changes.blank? ? 0 : tc_p2_that_cat_now - changes[0]['tc_p2_that_cat']
        tc_p2_lawyers_change = changes.blank? ? 0 : tc_p2_lawyers_now - changes[0]['tc_p2_lawyers']
        tc_p2_judges_change = changes.blank? ? 0 : tc_p2_judges_now - changes[0]['tc_p2_judges']
        tco_p1_damage_change = changes.blank? ? 0 : tco_p1_damage_now - changes[0]['tco_p1_damage']
        tc_p1_damage_change = changes.blank? ? 0 : tc_p1_damage_now - changes[0]['tc_p1_damage']
        tco_p1_closed_change = changes.blank? ? 0 : tco_p1_closed_now - changes[0]['tco_p1_closed']
        tco_p1_act_pdf_change = changes.blank? ? 0 : tco_p1_act_pdf_now - changes[0]['tco_p1_act_pdf']
        ta_p1_change = changes.blank? ? 0 : ta_p1_now - changes[0]['ta_p1']
        ta_p2_change = changes.blank? ? 0 : ta_p2_now - changes[0]['ta_p2']
        hash = {
          date: today,
          tc: tc_now,
          tc_p1: tc_p1_now,
          tc_p2: tc_p2_now,
          tc_2020: tc_2020_now,
          tc_2020_p1: tc_2020_p1_now,
          tc_2020_p2: tc_2020_p2_now,
          tc_wv: tc_wv_now,
          tc_mo: tc_mo_now,
          tc_la: tc_la_now,
          tc_f3m: tc_f3m_now,
          tuc_2020: tuc_2020_now,
          tuc_2020_pdf: tuc_2020_pdf_now,
          tuc_2020_pdf_p1: tuc_2020_pdf_p1_now,
          tuc_2020_pdf_p2: tuc_2020_pdf_p2_now,
          tuc_pdf_not_tried: tuc_pdf_not_tried_now,
          tuc_not_pdf: tuc_not_pdf_now,
          tuc_not_pdf_rt: tuc_not_pdf_rt_now,
          tuc_2020_not_pdf: tuc_2020_not_pdf_now,
          tuc_2020_not_pdf_rt: tuc_2020_not_pdf_rt_now,
          tuc_2020_as: tuc_2020_as_now,
          tuc_3m: tuc_3m_now,
          tuc_either: tuc_either_now,
          tco_p2: tco_p2_now,
          tco_p2_x: tco_p2_x_now,
          tco_p2_y: tco_p2_y_now,
          tco_p2_50: tco_p2_50_now,
          tco_p2_not_scrap: tco_p2_not_scrap_now,
          tj_p2: tj_p2_now,
          tc_2020_p2_appeal: tc_2020_p2_appeal_now,
          tc_2020_p2_supreme: tc_2020_p2_supreme_now,
          tc_2020_p2_lower: tc_2020_p2_lower_now,
          tc_p2_pdf: tc_p2_pdf_now,
          tc_p2_that_cat: tc_p2_that_cat_now,
          tc_p2_lawyers: tc_p2_lawyers_now,
          tc_p2_judges: tc_p2_judges_now,
          tco_p1_damage: tco_p1_damage_now,
          tc_p1_damage: tc_p1_damage_now,
          tco_p1_closed: tco_p1_closed_now,
          tco_p1_act_pdf: tco_p1_act_pdf_now,
          ta: ta_now,
          ta_p1: ta_p1_now,
          ta_p2: ta_p2_now
        }
        AnalysLitigationTotals.insert(hash)
        message = <<~TEXT
          <@#{john_putz}> <@#{rylan_klatt}> <@#{igor_sas}>
          We have: 
            1.  Total cases: `#{add_commas(tc_now)}`
                → Total Phase I court cases: `#{add_commas(tc_p1_now)}` (14 days change: `#{add_commas(tc_p1_change, true)}`)
                → Total Phase II court cases: `#{add_commas(tc_p2_now)}` (14 days change: `#{add_commas(tc_p2_change, true)}`)
            2.  Total cases (2020+): `#{add_commas(tc_2020_now)}`
                → Total Phase I court cases (2020+): `#{add_commas(tc_2020_p1_now)}` (14 days change: `#{add_commas(tc_2020_p1_change, true)}`)
                → Total Phase II court cases (2020+): `#{add_commas(tc_2020_p2_now)}` (14 days change: `#{add_commas(tc_2020_p2_change, true)}`)
            3.  Total West Virginia (WV) cases: `#{add_commas(tc_wv_now)}` (14 days change: `#{add_commas(tc_wv_change, true)}`)
            4.  Total Missouri (MO) cases: `#{add_commas(tc_mo_now)}` (14 days change: `#{add_commas(tc_mo_change, true)}`)
            5.  Total Louisiana (LA) cases: `#{add_commas(tc_la_now)}` (14 days change: `#{add_commas(tc_la_change, true)}`)
            6.  Total cases filed in last 3 months: `#{add_commas(tc_f3m_now)}` cases from (#{today_3m.strftime('%Y-%m-%d')} ‧ #{today.strftime('%Y-%m-%d')})
            7.  Total uncategorized cases from 2020+: `#{add_commas(tuc_2020_now)}` (14 days change: `#{add_commas(tuc_2020_change, true)}`)
            8.  Total uncategorized cases from 2020+ with PDFs or Text where we tried to match them & failed: `#{add_commas(tuc_2020_pdf_now)}` (14 days change: `#{add_commas(tuc_2020_pdf_change, true)}`)
                → Total Phase I court uncategorized cases: `#{add_commas(tuc_2020_pdf_p1_now)}` (14 days change: `#{add_commas(tuc_2020_pdf_p1_change, true)}`)
                → Total Phase II court uncategorized cases: `#{add_commas(tuc_2020_pdf_p2_now)}` (14 days change: `#{add_commas(tuc_2020_pdf_p2_change, true)}`)
            9.  Total uncategorized cases that have PDFs or Text, but we have NOT tried matching, yet: `#{add_commas(tuc_pdf_not_tried_now)}` (14 days change: `#{add_commas(tuc_pdf_not_tried_change, true)}`) - *We don't know*
            10.  Total uncategorized cases that do not have PDFs or Text, yet: `#{add_commas(tuc_not_pdf_now)}` (14 days change: `#{add_commas(tuc_not_pdf_change, true)}`)
                → Of these `#{add_commas(tuc_not_pdf_now)}` cases, `#{add_commas(tuc_not_pdf_rt_now)}` have a case description or raw type.
            11. Total uncategorized cases from 2020+ that do not have PDFs or Text, yet: `#{add_commas(tuc_2020_not_pdf_now)}` (14 days change: `#{add_commas(tuc_2020_not_pdf_change, true)}`)
                → Of these `#{add_commas(tuc_2020_not_pdf_now)}` cases from 2020+, `#{add_commas(tuc_2020_not_pdf_rt_now)}` have a case description or raw type.
            12. Total uncategorized cases from appeals or supreme courts (2020+): `#{add_commas(tuc_2020_as_now)}` (14 days change: `#{add_commas(tuc_2020_as_change, true)}`)
            13. Total uncategorized cases added to data set in past 3 months: `#{add_commas(tuc_3m_now)}` (14 days change: `#{add_commas(tuc_3m_change, true)}`)
            14. Total uncategorized cases that have either (1) raw type, (2) pdfs or text match to, or (3) case description text: `#{add_commas(tuc_either_now)}` (14 days change: `#{add_commas(tuc_either_change, true)}`)
            15. Total Phase II courts in db: `#{add_commas(tco_p2_now)}` (`#{add_commas(tco_p2_x_now)}` of `~#{add_commas(tco_p2_y_now)}` Phase II courts in db -- *#{tco_p2_p_now}%* total project) (14 days change: `#{add_commas(tco_p2_change, true)}`)
                → Total Phase II courts id db with >= 50 cases: `#{add_commas(tco_p2_50_now)}` (14 days change: `#{add_commas(tco_p2_50_change, true)}`)
                → Total Phase II courts that cannot be scraped: `#{add_commas(tco_p2_not_scrap_now)}` (14 days change: `#{add_commas(tco_p2_not_scrap_change, true)}`)
            16. Total Phase II court judges: `#{add_commas(tj_p2_now)}` (14 days change: `#{add_commas(tj_p2_change, true)}`)
            17. Total Phase II cases from appeals courts (2020+): `#{add_commas(tc_2020_p2_appeal_now)}` (14 days change: `#{add_commas(tc_2020_p2_appeal_change, true)}`)
            18. Total Phase II cases from State or Federal Supreme courts (2020+): `#{add_commas(tc_2020_p2_supreme_now)}` (14 days change: `#{add_commas(tc_2020_p2_supreme_change, true)}`)
            19. Total Phase II cases from Appeals/Supreme courts that are matched to lower court cases (2020+): `#{add_commas(tc_2020_p2_lower_now)}` (14 days change: `#{add_commas(tc_2020_p2_lower_change, true)}`)
            20. Total Phase II cases with PDFs: `#{add_commas(tc_p2_pdf_now)}` (14 days change: `#{add_commas(tc_p2_pdf_change, true)}`)
            21. Total Phase II cases that are categorized: `#{add_commas(tc_p2_that_cat_now)}` (14 days change: `#{add_commas(tc_p2_that_cat_change, true)}`)
            22. Total Phase II cases with lawyers: `#{add_commas(tc_p2_lawyers_now)}` (14 days change: `#{add_commas(tc_p2_lawyers_change, true)}`)
            23. Total Phase II cases with judges: `#{add_commas(tc_p2_judges_now)}` (14 days change: `#{add_commas(tc_p2_judges_change, true)}`)
            24. Total Phase I Courts with damage amounts: `#{add_commas(tco_p1_damage_now)}` courts (out of `#{add_commas(total_p1_courts)}` total Phase I courts). (14 days change: `#{add_commas(tco_p1_damage_change, true)}` courts)
            25. Total Phase I Court cases with damage amounts: `#{add_commas(tc_p1_damage_now)}` cases. (14 days change: `#{add_commas(tc_p1_damage_change, true)}` cases)
            26. Total Phase I Courts with "Closed" cases: `#{add_commas(tco_p1_closed_now)}` courts (out of `#{add_commas(total_p1_courts)}` total Phase I courts). (14 days change: `#{add_commas(tco_p1_closed_change, true)}` courts)
            27. Total Phase I Courts with PDFs on activities: `#{add_commas(tco_p1_act_pdf_now)}` courts (14 days change: `#{add_commas(tco_p1_act_pdf_change, true)}` courts)
            28. Total activities: `#{add_commas(ta_now)}`
                → Total Phase I court activities: `#{add_commas(ta_p1_now)}` (14 days change: `#{add_commas(ta_p1_change, true)}`)
                → Total Phase II court activities: `#{add_commas(ta_p2_now)}` (14 days change: `#{add_commas(ta_p2_change, true)}`)
        TEXT
        Slack.configure do |config|
          config.token = Storage.new.slack
        end
        Slack::Web::Client.new.chat_postMessage(channel: litigation_channel, text: message, as_user: true)
        Hamster.logger.info "Message send - Ok."
      rescue => e
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        Hamster.logger.error e.full_message
        message_send(title, message)
      end
    end
  end
end