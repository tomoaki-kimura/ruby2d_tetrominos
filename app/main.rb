require "./config"

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
