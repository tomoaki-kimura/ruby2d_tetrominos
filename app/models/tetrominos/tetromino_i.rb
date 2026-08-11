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
