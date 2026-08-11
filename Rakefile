task default: %w[game]

task :game do
  ruby "app/main.rb"
end

task :wasm do
  require "fileutils"
  FileUtils.mkdir_p ".bundle"

  files = [
    "settings.rb",
    "app/models/blocks/block.rb",
    "app/models/blocks/block_map.rb",
    "app/models/tetrominos/tetromino_base.rb",
    "app/models/tetrominos/tetromino_i.rb",
    "app/models/tetrominos/tetromino_j.rb",
    "app/models/tetrominos/tetromino_l.rb",
    "app/models/tetrominos/tetromino_o.rb",
    "app/models/tetrominos/tetromino_s.rb",
    "app/models/tetrominos/tetromino_t.rb",
    "app/models/tetrominos/tetromino_z.rb",
    "app/models/stage/stage.rb",
    "app/models/game/game.rb",
  ]

  bundle = %(require "ruby2d"\n\n)
  files.each { |f| bundle += File.read(f) + "\n" }

  main_body = File.read("app/main.rb").gsub(/^require.*\n/, "")
  bundle += main_body

  File.write(".bundle/bundle.rb", bundle)
  puts "Bundled → .bundle/bundle.rb"

  sh "ruby2d build --web .bundle/bundle.rb"

  FileUtils.cp "web/index.html", "build/web/app.html"
  puts "Template applied → build/web/app.html"
end

task :serve do
  puts "Serving at http://localhost:8080/app.html"
  sh "python3 -m http.server 8080 --directory build/web"
end
