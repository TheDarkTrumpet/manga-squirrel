require 'manga-squirrel/series'

module Manga
  module Squirrel
    class Manga::Squirrel::MangaFoxSeries
      include Manga::Squirrel::Series

      BASE_URL = "http://m.mangafox.com"
      IMG_DIV = "body>p>a>img"

      CHAPTER_NUMBER_REGEX = /.+\/?c([\d.]+)\//

      CHAPTER_LIST_CSS = 'ol a'

      CHAPTER_INFO_CSS = 'title'
      #Gives series, x, volume, chapter, caption
      CHAPTER_INFO_REGEX = /(: )?(.*?)( Vol.([X0-9]+) )?Ch.([0-9\.]+):? ?(.*)( - Manga Fox Mobile)+$/

      PAGES_CSS = 'body'
      PAGES_REGEX = /Page: (([0-9]+), )+Next Chapter/

      NO_WARNING = "?no_warning=1"

      private
      def getSeriesURL(warn=false)
        #Because of mangafox's systematic naming system - we can always find them
        url = "#{BASE_URL}/manga/#{urlify(@name.strip)}"
        if warn then
          url += NO_WARNING
        end
        return url
      end

      def getChapterNumberFromURL(url)
        url.match(CHAPTER_NUMBER_REGEX)[1].to_f
      end

      def parseChapterURLList(doc)
        doc.collect { |node| [node.attribute('href').value, nil] }.reverse
      end

      def getChapterURLList(doc)
        list = parseChapterURLList(doc)
        #Because mobile site paginates these links, need to check for more...
        nextPage = 2
        lastChaptersAdded = list
        while true do
          url = File.join(getSeriesURL(), "#{nextPage}.htm#{NO_WARNING}");
          docn = Nokogiri::HTML(open(url))

          toAdd = parseChapterURLList(docn.css(CHAPTER_LIST_CSS))
          if toAdd == lastChaptersAdded then
            break
          else
            toAdd.each { |x| list.push x }
            lastChaptersAdded = toAdd
            nextPage += 1
          end
        end

        return list
      end

      def getChapterInfoProcess(t)
        return @name,t[3],t[4].to_f,t[5]
      end

      def getPages(doc, chapter)
        num_pages = doc.at_css(PAGES_CSS).text.match(PAGES_REGEX)[1].to_i
        num_pages.times.map { |i| {:url=>getPageURL(chapter, i+1), :num=>i+1} }
      end

      def getPageURL(chapter, page)
        return "#{getSeriesURL}/c#{outNum chapter[:chapter]}/#{page}.html" if chapter[:volume].nil?

        "#{getSeriesURL}/v#{chapter[:volume]}/c#{outNum chapter[:chapter]}/#{page}.html"
      end
    end
  end
end
