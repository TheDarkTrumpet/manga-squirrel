require 'manga-squirrel/series'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaFoxSeries
      include Manga::Squirrel::Series

      BASE_URL = "http://www.mangafox.com"
      IMG_DIV = "#image"

      CHAPTER_LIST_CSS = 'table#listing td a.ch'

      CHAPTER_INFO_CSS = 'meta[property="og:title"]'
      #Gives series, x, volume, chapter, caption
      CHAPTER_INFO_REGEX = /(.*?) Manga (Vol\.([X0-9]+) )?Ch\.([0-9\.]+):? ?(.*)$/

      PAGES_CSS = 'select.middle'
      PAGES_REGEX = /<option value=\"([^']*?)\"[^>]*>\s*(\d*)<\/option>/

      private
      def getSeriesURL()
        #Because of mangafox's systematic naming system - we can always find them
        "#{BASE_URL}/manga/#{urlify(@name.strip)}"
      end

      def getChapterURLList(doc)
        doc.collect { |node| BASE_URL + node.attribute('href').value }.reverse
      end

      def getChapterInfoProcess(t)
        return t[0],t[2],t[3].to_f,t[4]
      end

      def getPageURL(chapter, page)
        "#{getSeriesURL}/v#{chapter[:volume]}/c#{"%03d" % chapter[:chapter]}/#{page}.html"
      end
    end
  end
end
