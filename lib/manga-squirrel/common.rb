require 'fileutils'
require 'manga-squirrel/mangafox'

module Manga
  module Squirrel
    module QueueAction
      Download = 0
      Archive = 1
    end
    module Site
      MangaFox = 0
    end

    def gendir(chapter)
      File.join(chapter[:series], "#{[chapter[:volume], chapter[:chapter]].compact.join('-')} #{chapter[:caption]}")
    end
  end
end