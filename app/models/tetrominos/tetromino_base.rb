class TetrominoBase < Block
  attr_accessor :tetromino_map

  def initialize(color)
    @origin_x   = 0
    @origin_y   = 0
    @grid_col   = 0
    @grid_row   = 0
    self.tetromino_map = mapping.map.with_index(0) do |row, row_index|
      row.map.with_index(0) do |col, col_index|
        if col == 1
          Block.new(
            color,
            @origin_x + Block.size * col_index,
            @origin_y + Block.size * row_index
          )
        end
      end
    end
    to_next_box
  end

  def left_rotate
    self.tetromino_map = rotate(tetromino_map.map(&:reverse).transpose)
  end

  def right_rotate
    self.tetromino_map = rotate(tetromino_map.transpose.map(&:reverse))
  end

  def move_left
    @grid_col -= 1
    move_to(@origin_x - GRID_SIZE, @origin_y)
  end

  def move_right
    @grid_col += 1
    move_to(@origin_x + GRID_SIZE, @origin_y)
  end

  def move_down
    @grid_row += 1
    move_to(@origin_x, @origin_y + GRID_SIZE)
  end

  def move_up
    @grid_row -= 1
    move_to(@origin_x, @origin_y - GRID_SIZE)
  end

  def to_next_box
    cols = tetromino_map[0].size
    rows = tetromino_map.size
    new_x = PANEL_OFFSET_X + (GRID_SIZE * 6 - GRID_SIZE * cols) / 2
    new_y = GRID_SIZE + (GRID_SIZE * 5 - GRID_SIZE * rows) / 2
    move_to(new_x, new_y)
  end


  def to_start_position
    @grid_col = (GRID_COLS - tetromino_map[0].size) / 2
    @grid_row = 0
    move_to(BOARD_OFFSET_X + GRID_SIZE * @grid_col, BOARD_OFFSET_Y + GRID_SIZE * @grid_row)
  end

  def grid_col = @grid_col
  def grid_row = @grid_row

  private

  def move_to(new_x, new_y)
    dx = new_x - @origin_x
    dy = new_y - @origin_y
    @origin_x = new_x
    @origin_y = new_y
    tetromino_map.each do |row|
      row.each do |block|
        next unless block
        block.x += dx
        block.y += dy
      end
    end
  end

  def rotate(rotated_map)
    rotated_map.map.with_index do |row, row_index|
      row.map.with_index do |block, col_index|
        if block
          block.x = @origin_x + Block.size * col_index
          block.y = @origin_y + Block.size * row_index
        end
        block
      end
    end
  end

  def mapping
    [
      [0, 0, 0],
      [0, 0, 0],
      [0, 0, 0],
    ]
  end
end
