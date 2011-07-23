require 'manga-squirrel/site'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaReaderSeries < Manga::Squirrel::Series
      @base_url = "http://www.mangareader.net"
      @img_div = "#img"

      @series_list_css = 'div[class^="series_col"]'
      @series_list_regex = /<li>$*<a href="([^"]*)">([^<]*)<\/a>/ 

      @chapter_list_css = 'div[id^="chapterlist"]'
      @chapter_list_regex = /<a href="([^"]*)">([^<]*)<\/a> : ([^<]*)<\/td>/

      @chapter_info_css = 'meta[name="description"]'
      #Gives: series, caption, chapter, page
      @chapter_info_regex = /(.+): (.+) ([0-9]+) - Read .* Page ([0-9]+)\./

      @pages_css = 'select[id^="pageMenu"]'
      @pages_regex = /<option value=\"([^']*?)\"[^>]*>\s*(\d*)<\/option>/

      private
      def getSeriesURL()
        #Because of mangareader's random system, we need to go look it up
        doc = Nokogiri::HTML(open(@base_url + "/alphabetical"))
        seriesList = doc.css(@series_list_css).to_s
        series = {}
        seriesList.scan(@series_list_regex).peach {
          |s|
          if @series.strip.urlify == s[1].strip.urlify
            return s[0]
          end
        }
        raise SeriesNotFound
      end

      def getChapterURLList(doc)
        doc.to_s.scan(@chapter_list_regex).collect { |c| @base_url + c[0] }
      end

      def getChapterInfoProcess(t)
        return t[0],nil,t[2].to_f,t[1]
      end

      def getPageURL(page)
        @base_url + page
      end
    end
  end
end
