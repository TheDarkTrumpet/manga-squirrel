require 'nokogiri'
require 'open-uri'
require 'fileutils'

module Manga
  module Squirrel
    class Worker
      @queue  = 'manga-squirrel'

      def self.perform(series, volume, chapter, caption, page, url)
        doc = Nokogiri::HTML(open(url))

        img = doc.css('#image').attribute('src').value
        ext = img.gsub(/\.*(\.[^\.]*)$/).first

        FileUtils.mkdir_p dir = File.join(series, "#{[volume, chapter].compact.join('-')} #{caption}")

        system 'curl', img, "-o", File.join(dir, "#{"%03d" % page}#{ext}")
      end
    end
  end
end