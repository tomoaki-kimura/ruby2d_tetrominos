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
