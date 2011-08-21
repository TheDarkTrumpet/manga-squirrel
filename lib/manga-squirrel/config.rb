require 'yaml'

module Manga
  module Squirrel
    class ConfigFile
      def parse(file="~/.ms")
        fp = File.expand_path file
        raise FileNotFound unless File.exists? fp

        YAML.load_file(fp) do
          |config|
          config[:series].each do
            |series|
            site = "Manga::Squirrel::#{(series[:site] || config[:site] || "MangaFox")}".to_class
            raw = series[:raw] || config[:raw] || "~/"
            out = series[:out] || config[:out] || "~/"
            autocbz = series[:autocbz] || config[:autocbz] || false
            yield series[:name], site, raw, out, autocbz
          end
        end
      end
    end
  end
end
