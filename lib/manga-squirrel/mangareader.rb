require 'manga-squirrel/series'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaReaderSeries 
      include Manga::Squirrel::Series

      BASE_URL = "http://www.mangareader.net"
      IMG_DIV = "#img"

      SERIES_LIST_CSS = 'div[class^="series_col"]'
      SERIES_LIST_REGEX = /<li>$*<a href="([^"]*)">([^<]*)<\/a>/ 

      CHAPTER_LIST_CSS = 'div[id^="chapterlist"]'
      CHAPTER_LIST_REGEX = /<a href="([^"]*)">([^<]*)<\/a> : ([^<]*)<\/td>/

      CHAPTER_INFO_CSS = 'meta[name="description"]'
      #Gives: series, caption, chapter, page
      CHAPTER_INFO_REGEX = /(.+) ([0-9]+) - Read .* Page ([0-9]+)\./

      PAGES_CSS = 'select[id^="pageMenu"]'
      PAGES_REGEX = /<option value=\"([^']*?)\"[^>]*>\s*(\d*)<\/option>/

      private
      def getSeriesURL()
        #Because of mangareader's random system, we need to go look it up
        doc = Nokogiri::HTML(open(BASE_URL + "/alphabetical"))
        seriesList = doc.css(SERIES_LIST_CSS).to_s
        series = {}
        seriesList.scan(SERIES_LIST_REGEX).each {
          |s|
          if urlify(@series.strip) == urlify(s[1].strip)
            return BASE_URL + s[0]
          end
        }
        raise SeriesNotFound
      end

      def getChapterURLList(doc)
        doc.to_s.scan(CHAPTER_LIST_REGEX).collect { |c| BASE_URL + c[0] }
      end

      def getChapterInfoProcess(t)
        return t[0],nil,t[1].to_f,t[2]
      end

      def getPageURL(chapter, page)
        BASE_URL + page
      end
    end
  end
end
