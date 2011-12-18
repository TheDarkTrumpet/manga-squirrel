require 'manga-squirrel/series'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaReaderSeries
      include Manga::Squirrel::Series

      BASE_URL = "http://www.mangareader.net"
      IMG_DIV = "#img"

      SERIES_LIST_CSS = 'div[class^="series_col"]'
      SERIES_LIST_REGEX = /<li>$*<a href="([^"]*)">([^<]*)<\/a>/

      CHAPTER_NUMBER_REGEX = /([\d.]+)/

      CHAPTER_LIST_CSS = 'div[id^="chapterlist"]'
      #Gives: url, (name + number), caption
      CHAPTER_LIST_REGEX = /<a href="([^"]*)">([^<]*)<\/a> : ([^<]*)<\/td>/

      CHAPTER_INFO_CSS = 'title'
      #Gives: series, -  chapter, page
      CHAPTER_INFO_REGEX = /(.+) ([0-9]+) - Read .* Page ([0-9]+)/

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
          if urlify(@name.strip) == urlify(s[1].strip)
            return BASE_URL + s[0]
          end
        }
        raise SeriesNotFound
      end

      def getChapterNumberFromURL(url)
        File.basename(url).match(CHAPTER_NUMBER_REGEX)[1].to_f
      end

      def getChapterURLList(doc)
        doc.to_s.scan(CHAPTER_LIST_REGEX).collect { |c| [BASE_URL + c[0], c[2]] }
      end

      def getChapterInfoProcess(t)
        return t[0],nil,t[1].to_f,t[2]
      end

      def getPages(doc, chapter)
        doc.css(PAGES_CSS).to_s.scan(PAGES_REGEX).map { |x| {:url=>getPageURL(chapter, x[0]), :num=>x[1]} }
      end

      def getPageURL(chapter, page)
        BASE_URL + page
      end
    end
  end
end
