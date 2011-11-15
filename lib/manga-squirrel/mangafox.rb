require 'manga-squirrel/series'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaFoxSeries
      include Manga::Squirrel::Series

      BASE_URL = "http://www.mangafox.com"
      IMG_DIV = "#image"

      CHAPTER_NUMBER_REGEX = /.+\/?c([\d.]+)\//

      CHAPTER_LIST_CSS = 'table#listing td a.ch'

      CHAPTER_INFO_CSS = 'meta[property="og:title"]'
      #Gives series, x, volume, chapter, caption
      CHAPTER_INFO_REGEX = /(.*?) Manga (Vol\.([X0-9]+) )?Ch\.([0-9\.]+):? ?(.*)$/

      PAGES_CSS = 'script'
      PAGES_REGEX = /var\s+total_pages\s*=\s*(\d+);/

      private
      def getSeriesURL()
        #Because of mangafox's systematic naming system - we can always find them
        "#{BASE_URL}/manga/#{urlify(@name.strip)}"
      end

      def getChapterNumberFromURL(url)
        url.match(CHAPTER_NUMBER_REGEX)[0]
      end

      def getChapterURLList(doc)
        doc.collect { |node| [BASE_URL + node.attribute('href').value, nil] }.reverse
      end

      def getChapterInfoProcess(t)
        return t[0],t[2],t[3].to_f,t[4]
      end

      def getPages(doc, chapter)
        num_pages = doc.css(PAGES_CSS).to_s.match(PAGES_REGEX)[1].to_i
        pbar = ProgressBar.new("Pages: C#{chapter[:chapter]}", num_pages) unless $isDaemon
        ret = num_pages.times.map do
          |i|
          pbar.inc unless $isDaemon
          {:url=>getPageURL(chapter, i+1), :num=>i+1}
          end
        pbar.finish unless $isDaemon
        return ret
      end

      def getPageURL(chapter, page)
        return "#{getSeriesURL}/c#{outNum chapter[:chapter]}/#{page}.html" if chapter[:volume].nil?

        "#{getSeriesURL}/v#{chapter[:volume]}/c#{outNum chapter[:chapter]}/#{page}.html"
      end
    end
  end
end
