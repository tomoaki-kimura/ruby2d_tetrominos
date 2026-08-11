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
