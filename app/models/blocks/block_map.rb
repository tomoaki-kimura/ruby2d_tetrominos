class BlockMap
  def initialize
    @grid = Array.new(GRID_ROWS) { Array.new(GRID_COLS) }
  end

  def collide?(tetromino_map, offset_col, offset_row)
    tetromino_map.each.with_index do |row, row_index|
      row.each.with_index do |block, col_index|
        next unless block

        col = offset_col + col_index
        r   = offset_row + row_index

        return true if col < 0 || col >= GRID_COLS
        return true if r >= GRID_ROWS
        return true if r >= 0 && @grid[r][col]
      end
    end
    false
  end

  def settle(tetromino_map, offset_col, offset_row)
    tetromino_map.each.with_index do |row, row_index|
      row.each.with_index do |block, col_index|
        next unless block
        r = offset_row + row_index
        if r >= 0
          block.dim!
          @grid[r][offset_col + col_index] = block
        end
      end
    end
    complete_rows
  end

  def flash(row_indices, bright)
    row_indices.each do |i|
      @grid[i].compact.each { |b| bright ? b.flash_on : b.flash_off }
    end
  end

  def clear_rows(row_indices)
    row_indices.each { |i| @grid[i].compact.each(&:remove) }
    @grid.reject!.with_index { |_, i| row_indices.include?(i) }
    row_indices.size.times { @grid.unshift(Array.new(GRID_COLS)) }
    redraw_all
    row_indices.size
  end

  def top_filled?
    @grid[0].any?
  end

  def reset
    @grid.each { |row| row.compact.each(&:remove) }
    @grid = Array.new(GRID_ROWS) { Array.new(GRID_COLS) }
  end

  private

  def complete_rows
    @grid.each.with_index
         .select { |row, _| row.none?(&:nil?) }
         .map { |_, i| i }
  end

  def redraw_all
    @grid.each.with_index do |row, row_index|
      row.each do |block|
        next unless block
        block.y = BOARD_OFFSET_Y + GRID_SIZE * row_index
      end
    end
  end
end
