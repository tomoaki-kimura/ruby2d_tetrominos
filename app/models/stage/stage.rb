class Stage
  WALL_COLOR  = [0.25, 0.25, 0.28, 1]
  BOARD_COLOR = [0.08, 0.08, 0.12, 1]
  TEXT_COLOR  = "white"
  TEXT_SIZE   = GRID_SIZE - 4
  GATE_WIDTH  = 1

  attr_reader :score_text, :high_score_text, :level_text

  def initialize
    draw_wall
    draw_board
    draw_gate
    draw_next_area
    draw_next_label
    draw_score_labels
  end

  def update_score(score, high_score, level)
    reflow_text(@score_text,      score.to_s)
    reflow_text(@high_score_text, high_score.to_s)
    reflow_text(@level_text,      level.to_s)
  end

  private

  def draw_wall
    Rectangle.new(
      x: 0, y: 0,
      width: SCREEN_WIDTH,
      height: SCREEN_HEIGHT,
      color: WALL_COLOR
    )
  end

  def draw_board
    Rectangle.new(
      x: BOARD_OFFSET_X - Block::MARGIN,
      y: BOARD_OFFSET_Y - Block::MARGIN,
      width: GRID_SIZE * GRID_COLS + Block::MARGIN,
      height: GRID_SIZE * GRID_ROWS + Block::MARGIN,
      color: BOARD_COLOR
    )
  end

  def draw_gate
    gate_height = GRID_SIZE * GATE_WIDTH

    Rectangle.new(
      x: BOARD_OFFSET_X - Block::MARGIN,
      y: 0,
      width: GRID_SIZE * GATE_WIDTH,
      height: gate_height - Block::MARGIN,
      color: WALL_COLOR
    )

    Rectangle.new(
      x: BOARD_OFFSET_X + GRID_SIZE * (GRID_COLS - GATE_WIDTH),
      y: 0,
      width: GRID_SIZE * GATE_WIDTH,
      height: gate_height - Block::MARGIN,
      color: WALL_COLOR
    )
  end

  def draw_next_area
    Rectangle.new(
      x: PANEL_OFFSET_X,
      y: GRID_SIZE,
      width: GRID_SIZE * 6,
      height: GRID_SIZE * 6,
      color: BOARD_COLOR
    )
  end

  def draw_next_label
    draw_centered_text("NEXT", GRID_SIZE * 6)
  end

  def draw_score_labels
    draw_centered_text("SCORE", GRID_SIZE * 9)
    @score_text = draw_centered_text("0", GRID_SIZE * 10)

    draw_centered_text("HIGH", GRID_SIZE * 12)
    @high_score_text = draw_centered_text("0", GRID_SIZE * 13)

    draw_centered_text("LEVEL", GRID_SIZE * 15)
    @level_text = draw_centered_text("1", GRID_SIZE * 16)
  end

  def draw_centered_text(str, y)
    t = Text.new(str, size: TEXT_SIZE, color: TEXT_COLOR)
    t.x = PANEL_OFFSET_X + (GRID_SIZE * PANEL_COLS - t.width) / 2
    t.y = y
    t
  end

  def reflow_text(text_obj, new_str)
    text_obj.content = new_str
    text_obj.x = PANEL_OFFSET_X + (GRID_SIZE * PANEL_COLS - text_obj.width) / 2
  end
end
