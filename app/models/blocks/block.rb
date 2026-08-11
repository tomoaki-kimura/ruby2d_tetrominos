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

