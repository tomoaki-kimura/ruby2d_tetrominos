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
