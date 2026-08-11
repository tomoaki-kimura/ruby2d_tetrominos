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
