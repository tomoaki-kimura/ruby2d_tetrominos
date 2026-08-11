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
