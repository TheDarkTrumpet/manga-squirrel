require 'manga-squirrel/site'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaFoxSeries < Manga::Squirrel::Series
      @base_url = "http://www.mangafox.com"
      @img_div = "#image"

      @chapter_list_css = 'table#listing td a.ch'

      @chapter_info_css = 'meta[property="og:title"]'
      #Gives series, x, volume, chapter, caption
      @chapter_info_regex = /(.*?) Manga (Vol\.([X0-9]+) )?Ch\.([0-9\.]+):? ?(.*)$/


      private
      def getSeriesURL()
        #Because of mangafox's systematic naming system - we can always find them
        "#{@base_url}/manga/#{urlify(@series)}"
      end

      def getChapterURLList(doc)
        doc.collect { |node| @base_url + node.attribute('href').value }.reverse
      end

      def getChapterInfoProcess(t)
        return t[0],t[2],t[3],t[4]
      end

      def getPageURL(page)
        getSeriesURL + "/#{page}"
      end
    end
  end
end
