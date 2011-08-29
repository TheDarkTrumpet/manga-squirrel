require 'yaml'
require 'manga-squirrel/common'
require 'manga-squirrel/series'

module Manga
  module Squirrel
    class ConfigFile
      def self.parse(file="~/.ms")
        fp = File.expand_path file
        raise FileNotFound unless File.exists? fp

        config = YAML.load_file(fp)
        config[:series].each do
          |series|
          sclass = "Manga::Squirrel::#{(series[:site] || config[:site] || "MangaFox")}Series".to_class
          name = series[:name]
          raw = File.expand_path(series[:raw] || config[:raw] || "~/")
          out = File.expand_path(series[:out] || config[:out] || "~/")
          autocbz = series[:autocbz] || config[:autocbz] || false
          volume = series[:volume] || "true"
          chapter = series[:chapter] || "true"
          cbf = series[:cbf] || config[:cbf] || "cbz"

          yield name,sclass,raw,out,autocbz,volume,chapter,cbf
        end
      end
    end
  end
end
