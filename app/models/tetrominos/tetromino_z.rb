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
