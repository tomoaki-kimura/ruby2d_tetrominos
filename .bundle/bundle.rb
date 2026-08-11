require "ruby2d"

GRID_SIZE     = 15
GRID_COLS     = 10
GRID_ROWS     = 20
PANEL_COLS    = 7

SCREEN_WIDTH  = GRID_SIZE * (1 + GRID_COLS + 1 + PANEL_COLS)  # 左壁 + ボード + 右壁 + パネル
SCREEN_HEIGHT = GRID_SIZE * (GRID_ROWS + 1)                    # ボード + 下壁

FALL_INTERVAL       = 60
SOFT_DROP_INTERVAL  = 6
LINES_PER_LEVEL     = 10
FLASH_DURATION      = 60
FLASH_INTERVAL      = 6
LOCK_DELAY          = 30
DAS                 = 10
ARR                 = 2

BOARD_OFFSET_X = GRID_SIZE
BOARD_OFFSET_Y = 0
PANEL_OFFSET_X = GRID_SIZE * (1 + GRID_COLS + 1)

class Block < Square
  MARGIN = 1

  attr_reader :is_active

  def initialize(color, x, y)
    @base_color = color
    super(color: color, x: x, y: y, size: GRID_SIZE - MARGIN)
  end

  def self.size
    GRID_SIZE
  end

  def dim!
    c = self.color
    self.color = [c.r * 0.85, c.g * 0.85, c.b * 0.85, c.a]
  end

  def flash_on
    self.color = [1, 1, 1, 1]
  end

  def flash_off
    self.color = @base_color
  end

  private

  def to_active
    @is_active = true
  end

  def to_inactive
    @is_active = false
  end
end


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

class TetrominoI < TetrominoBase

  def initialize
    super("aqua")
  end

  private

  def mapping
    [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]
  end
end

class TetrominoJ < TetrominoBase

  def initialize
    super("blue")
  end

  private

  def mapping
    [
      [0, 0, 0],
      [1, 1, 1],
      [0, 0, 1]
    ]
  end
end

class TetrominoL < TetrominoBase

  def initialize
    super("orange")
  end

  private

  def mapping
    [
      [0, 0, 0],
      [1, 1, 1],
      [1, 0, 0],
    ]
  end
end

class TetrominoO < TetrominoBase

  def initialize
    super("yellow")
  end

  private

  def mapping
    [
      [1, 1],
      [1, 1],
    ]
  end
end

class TetrominoS < TetrominoBase

  def initialize
    super("lime")
  end

  private

  def mapping
    [
      [0, 1, 1],
      [1, 1, 0],
      [0, 0, 0],
    ]
  end
end

class TetrominoT < TetrominoBase

  def initialize
    super("purple")
  end

  private

  def mapping
    [
      [0, 0, 0],
      [1, 1, 1],
      [0, 1, 0],
    ]
  end
end

class TetrominoZ < TetrominoBase

  def initialize
    super("red")
  end

  private

  def mapping
    [
      [0, 0, 0],
      [1, 1, 0],
      [0, 1, 1],
    ]
  end
end

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

class Game
  TETROMINO_CLASSES = [
    TetrominoI, TetrominoJ, TetrominoL,
    TetrominoO, TetrominoS, TetrominoT, TetrominoZ
  ].freeze

  attr_reader :current, :next_tetromino, :score, :high_score, :level

  def initialize
    @bag            = []
    @score          = 0
    @high_score     = 0
    @level          = 1
    @lines_cleared  = 0
    @frame_count    = 0
    @lock_timer     = 0
    @soft_drop      = false
    @held_dir       = nil
    @das_timer      = 0
    @arr_timer      = 0
    @state          = :playing
    @flash_rows     = []
    @flash_timer    = 0
    @flash_bright   = false
    @block_map       = BlockMap.new
    @game_over_texts = []
    @start_texts     = []
    @next_tetromino = pick
    enter_waiting
  end

  def advance
    @current        = @next_tetromino
    @next_tetromino = pick
    @current.to_start_position
    @state       = :playing
    @frame_count = 0

    if @block_map.collide?(@current.tetromino_map, @current.grid_col, @current.grid_row)
      enter_game_over
    end
  end

  def update
    case @state
    when :playing   then update_playing
    when :landing   then update_landing
    when :flashing  then update_flashing
    when :waiting, :game_over then nil
    end
  end

  def on_key_down(key)
    if @state == :waiting
      start_game if key == "space"
      return
    end

    if @state == :game_over
      restart if key == "r"
      return
    end

    return unless @state == :playing || @state == :landing

    case key
    when "a"
      @held_dir  = :left
      @das_timer = 0
      @arr_timer = 0
      move_horizontal(:left)
    when "d"
      @held_dir  = :right
      @das_timer = 0
      @arr_timer = 0
      move_horizontal(:right)
    when "s"
      @soft_drop = true if @state == :playing
    when "j"
      @current.left_rotate
      if @block_map.collide?(@current.tetromino_map, @current.grid_col, @current.grid_row)
        @current.right_rotate
      else
        check_grounded
      end
    when "k"
      @current.right_rotate
      if @block_map.collide?(@current.tetromino_map, @current.grid_col, @current.grid_row)
        @current.left_rotate
      else
        check_grounded
      end
    end
  end

  def on_key_up(key)
    @soft_drop = false if key == "s"
    @held_dir  = nil  if key == "a" || key == "d"
  end

  private

  def update_playing
    update_das
    @frame_count += 1
    interval = @soft_drop ? SOFT_DROP_INTERVAL : fall_interval
    if @frame_count >= interval
      @frame_count = 0
      fall
    end
  end

  def update_landing
    update_das
    @lock_timer += 1
    settle_current if @lock_timer >= LOCK_DELAY
  end

  def update_das
    return unless @held_dir

    @das_timer += 1
    return if @das_timer < DAS

    @arr_timer += 1
    if @arr_timer >= ARR
      @arr_timer = 0
      move_horizontal(@held_dir)
    end
  end

  def update_flashing
    @flash_timer += 1
    if @flash_timer % FLASH_INTERVAL == 0
      @flash_bright = !@flash_bright
      @block_map.flash(@flash_rows, @flash_bright)
    end
    if @flash_timer >= flash_duration
      @block_map.flash(@flash_rows, false)
      count = @block_map.clear_rows(@flash_rows)
      add_score(count)
      advance
    end
  end

  def fall
    @current.move_down
    if @block_map.collide?(@current.tetromino_map, @current.grid_col, @current.grid_row)
      @current.move_up
      @state      = :landing
      @lock_timer = 0
    end
  end

  def move_horizontal(dir)
    if dir == :left
      @current.move_left
      if @block_map.collide?(@current.tetromino_map, @current.grid_col, @current.grid_row)
        @current.move_right
      else
        check_grounded
      end
    else
      @current.move_right
      if @block_map.collide?(@current.tetromino_map, @current.grid_col, @current.grid_row)
        @current.move_left
      else
        check_grounded
      end
    end
  end

  def check_grounded
    @current.move_down
    if @block_map.collide?(@current.tetromino_map, @current.grid_col, @current.grid_row)
      @current.move_up
      @lock_timer = 0
    else
      @current.move_up
      @state = :playing
    end
  end

  def settle_current
    rows = @block_map.settle(@current.tetromino_map, @current.grid_col, @current.grid_row)
    if rows.any?
      @flash_rows   = rows
      @flash_timer  = 0
      @flash_bright = false
      @state        = :flashing
    else
      advance
    end
  end

  def enter_waiting
    @state = :waiting
    title = Text.new("BLOCK GAME", size: GRID_SIZE, color: "white")
    title.x = BOARD_OFFSET_X + (GRID_SIZE * GRID_COLS - title.width) / 2
    title.y = GRID_SIZE * GRID_ROWS / 2 - GRID_SIZE * 2
    hint = Text.new("SPACE to start", size: GRID_SIZE - 4, color: "white")
    hint.x = BOARD_OFFSET_X + (GRID_SIZE * GRID_COLS - hint.width) / 2
    hint.y = GRID_SIZE * GRID_ROWS / 2
    @start_texts = [title, hint]
  end

  def start_game
    @start_texts.each(&:remove)
    @start_texts = []
    advance
  end

  def enter_game_over
    @state = :game_over
    label = Text.new("GAME OVER", size: GRID_SIZE, color: "white")
    label.x = BOARD_OFFSET_X + (GRID_SIZE * GRID_COLS - label.width) / 2
    label.y = GRID_SIZE * GRID_ROWS / 2 - GRID_SIZE

    hint = Text.new("r: restart", size: GRID_SIZE - 4, color: "white")
    hint.x = BOARD_OFFSET_X + (GRID_SIZE * GRID_COLS - hint.width) / 2
    hint.y = GRID_SIZE * GRID_ROWS / 2 + GRID_SIZE

    @game_over_texts = [label, hint]
  end

  def restart
    @game_over_texts&.each(&:remove)
    @game_over_texts = []
    @current.tetromino_map.flatten.compact.each(&:remove)
    @next_tetromino.tetromino_map.flatten.compact.each(&:remove)
    @block_map.reset

    @bag           = []
    @score         = 0
    @level         = 1
    @lines_cleared = 0
    @frame_count   = 0
    @lock_timer    = 0
    @soft_drop     = false
    @flash_rows    = []
    @next_tetromino = pick
    advance
  end

  def add_score(line_count)
    points = [0, 100, 300, 500, 800][line_count] * @level
    @score += points
    @high_score = @score if @score > @high_score
    @lines_cleared += line_count
    @level = @lines_cleared / LINES_PER_LEVEL + 1
  end

  def fall_interval
    [FALL_INTERVAL - (@level - 1) * 5, SOFT_DROP_INTERVAL].max
  end

  def flash_duration
    [FLASH_DURATION / @level, FLASH_INTERVAL * 2].max
  end

  def pick
    @bag = TETROMINO_CLASSES.shuffle if @bag.empty?
    @bag.pop.new
  end
end


set width: SCREEN_WIDTH, height: SCREEN_HEIGHT

stage = Stage.new
game  = Game.new

on :key_down do |event|
  game.on_key_down(event.key)
end

on :key_up do |event|
  game.on_key_up(event.key)
end

update do
  game.update
  stage.update_score(game.score, game.high_score, game.level)
end

show
