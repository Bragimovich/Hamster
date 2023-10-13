module Hamster
  class TableReceiver < PDF::Reader::PageTextReceiver
    def page=(page)
      super(page)

      @current_group = nil
      @next_group    = 0
      @content_tag   = nil
    end

    def begin_marked_content_with_pl(tag, properties)
      begin_marked_content(tag)
    end

    def begin_marked_content(tag)
      @content_tag   = tag
      @current_group = @next_group
      @next_group    += 1
    end

    def end_marked_content
      @current_group = nil
      @content_tag   = nil
    end

    def columns(opts = {})
      runs = @characters

      if rect = opts.fetch(:rect, @page.rectangles[:CropBox])
        runs = PDF::Reader::BoundingRectangleRunsFilter.runs_within_rect(runs, rect)
      end

      if opts.fetch(:skip_zero_width, true)
        runs = PDF::Reader::ZeroWidthRunsFilter.exclude_zero_width_runs(runs)
      end

      if opts.fetch(:skip_overlapping, true)
        runs = PDF::Reader::OverlappingRunsFilter.exclude_redundant_runs(runs)
      end

      runs = PDF::Reader::NoTextFilter.exclude_empty_strings(runs)
      runs = runs.chunk { |r| r.instance_variable_get(:@group) }.map { |_, r| r }
      runs = group_texts(runs)
      runs = group_columns(runs)

      runs
    end

    private

    def group_columns(runs)
      runs = runs.sort_by { |r| -r[:y] }.each_with_object([]) do |run, arr|
        arr << [run] and next if arr.empty?

        last_arr = arr.last
        base_run = last_arr.first

        intersecting_y1 = [base_run[:y], run[:y]].max
        intersecting_y2 = [base_run[:y] + base_run[:h], run[:y] + run[:h]].min
        intersecting_h  = intersecting_y2 - intersecting_y1

        if intersecting_h >= 1
          last_arr << run
        else
          arr << [run]
        end
      end

      runs.map do |run|
        run.sort_by { |r| r[:x] }.map { |r| r[:text] }
      end
    end

    def group_texts(runs)
      runs.map do |r|
        texts = merge_runs(r)

        texts.sort_by { |run| -run.origin.y }.each_with_object({}) do |run, hash|
          org_text = hash[:text]
          org_x    = hash[:x]
          org_y    = hash[:y]
          org_w    = hash[:w]
          org_h    = hash[:h]

          hash[:text] = (org_text.nil? || org_text.empty?) ? run.text : "#{org_text} #{run.text}"

          x, y, w, h = [run.origin.x, run.origin.y, run.width, run.font_size]
          x, y, w, h = merge_boundaries(org_x, org_y, org_w, org_h, x, y, w, h) unless org_x.nil?
          hash[:x] = x
          hash[:y] = y
          hash[:w] = w
          hash[:h] = h
        end
      end
    end

    def internal_show_text(string)
      return if @current_group.nil?
      return unless @content_tag == :P

      before_count = @characters.count
      super(string)
      after_count = @characters.count

      added_count = after_count - before_count
      (1..added_count).each do |idx|
        @characters[-idx].instance_variable_set(:@group, @current_group)
      end
    end

    def merge_boundaries(x1, y1, w1, h1, x2, y2, w2, h2)
      xend1 = x1 + w1
      yend1 = y1 + h1
      xend2 = x2 + w2
      yend2 = y2 + h2

      x    = [x1, x2].min
      y    = [y1, y2].min
      xend = [xend1, xend2].max
      yend = [yend1, yend2].max
      w    = xend - x
      h    = yend - y

      [x, y, w, h]
    end
  end
end
