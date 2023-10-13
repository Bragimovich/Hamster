# frozen_string_literal: true

class SharedProgress
  READ_BUFFER_SIZE = 128
  COUNT_ITEM_SIZE  = 8

  def initialize(store_path, delimiter = ',')
    raise 'Shared progress store path not specified.' if store_path.blank?

    @delimiter = delimiter || ','
    @delimiter = ',' unless @delimiter.is_a?(String) && @delimiter.size > 0
    @file_path = "#{store_path}/shared_progress.lock"

    @items_start_point = (COUNT_ITEM_SIZE + @delimiter.size) * 2
  end

  def pick_next_item(update_file = true)
    File.open(@file_path, File::RDWR | File::CREAT, 0644) do |file|
      file.flock(File::LOCK_EX)
      file_size = file.size
      return nil if file_size < @items_start_point

      file.seek(0)
      total_count  = file.readpartial(COUNT_ITEM_SIZE)
      file.seek(COUNT_ITEM_SIZE + @delimiter.size)
      remain_count = file.readpartial(COUNT_ITEM_SIZE)

      total_count  = total_count.to_i
      remain_count = remain_count.to_i

      return nil if total_count <= 0 || remain_count <= 0

      read_pos  = file_size
      last_str  = ''
      last_item = nil
      while true
        read_pos -= READ_BUFFER_SIZE
        if read_pos < @items_start_point
          read_len = READ_BUFFER_SIZE - (@items_start_point - read_pos)
          read_pos = @items_start_point
        else
          read_len = READ_BUFFER_SIZE
        end

        if read_len.zero?
          last_item = last_str if last_str.size > 0
          break
        end

        file.seek(read_pos)
        read_str = file.readpartial(read_len)
        last_str = read_str + last_str

        comps = last_str.split(@delimiter)
        if comps.size > 1
          last_item = comps.last
          break
        end
      end

      return nil if last_item.nil?

      if update_file
        file.seek(COUNT_ITEM_SIZE + @delimiter.size)
        file.write((remain_count - 1).to_s.rjust(COUNT_ITEM_SIZE, '0'))
        file.flush

        new_size = file_size - last_item.size - @delimiter.size
        new_size = @items_start_point if new_size < @items_start_point
        file.truncate(new_size)
      end

      [total_count, remain_count, last_item]
    end
  rescue SystemCallError, IOError
    nil
  end

  def store_items(items)
    return unless items.instance_of?(Array) && items.size > 0

    total_count = items.size
    File.open(@file_path, File::RDWR | File::CREAT, 0644) do |file|
      file.flock(File::LOCK_EX)
      file.truncate(0)
      file.seek(0)

      count_str = total_count.to_s.rjust(COUNT_ITEM_SIZE, '0')
      file.write(count_str)
      file.write(@delimiter)
      file.write(count_str)
      file.write(@delimiter)
      file.write(items.join(@delimiter))
      file.flush
    end
  end
end
