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

    def namesanitize(name)
      name.gsub(/[\\\?%*|"<>]/, '')
    end

    def gendir(chapter)
      File.join(chapter[:series], "#{[chapter[:volume], chapter[:chapter]].compact.join('-')} #{namesanitize(chapter[:caption])}")
    end
  end
end

class String
  def to_class
    chain = self.split "::"
    klass = Kernel
    chain.each do |klass_string|
      klass = klass.const_get klass_string
    end
    klass.is_a?(Class) ? klass : nil
  rescue NameError
    nil
  end
end
