require 'nokogiri'
require 'open-uri'
require 'fileutils'

module Manga
  module Squirrel
    class Worker
      @queue  = 'manga-squirrel'

      def self.gendir(series, volume, chapter, caption)
        return File.join(series, "#{[volume, chapter].compact.join('-')} #{caption}")
      end

      def self.perform(series, volume, chapter, caption, page, url, pages)
        doc = Nokogiri::HTML(open(url))

        img = doc.css('#image').attribute('src').value
        ext = img.gsub(/\.*(\.[^\.]*)$/).first

        FileUtils.mkdir_p dir = self.gendir(series, volume, chapter, caption)

        system 'curl', img, "-o", File.join(dir, "#{"%03d" % page}#{ext}")
		if page == pages then
          system 'zip', "-r", dir+".cbz", dir
        end
      end
    end
  end
end
