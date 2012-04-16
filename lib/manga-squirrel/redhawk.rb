require 'manga-squirrel/series'
require 'pp'

module Manga
  module Squirrel
    class Manga::Squirrel::RedHawkSeries
      include Manga::Squirrel::Series

      BASE_URL = "http://manga.redhawkscans.com/reader/"
      IMG_DIV = "div.inner>a>img.open"

      SERIES_LIST_CSS = 'div.panel div.title>a'

      CHAPTER_LIST_CSS = 'div.list div.element div.title>a'
      CHAPTER_LIST_REGEX = /Chapter \d+: (.*)/

      CHAPTER_NUMBER_REGEX = /(\d+)\/(\d+)\/$/

      CHAPTER_INFO_CSS = 'title'
      CHAPTER_INFO_REGEX = /(.*) :: Chapter ([\d.]+) ::/

      PAGES_CSS = 'div.topbar_right ul.dropdown>li>a'
      PAGES_REGEX = /Page (\d+)/

      private
      def getSeriesURL(warn=false)
        #Go look it up
        doc = Nokogiri::HTML(open(BASE_URL + "/list"))
        seriesList = doc.css(SERIES_LIST_CSS)
        seriesList.each {
          |s|
          if urlify(@name.strip) == urlify(s.child.to_s.strip)
            return s['href']
          end
        }
        raise FileNotFound
      end

      def getChapterURLList(doc)
        doc.collect {
          |x|
          caption = x.child.to_s.match(CHAPTER_LIST_REGEX)
          if caption != nil
            caption = caption[1]
          end
          [x['href'], caption]
        }
      end

      def getChapterNumberFromURL(url)
        m = url.match(CHAPTER_NUMBER_REGEX)
        if m.length == 3
          return m[2].to_f
        else
          return m[1].to_f + (m[2].to_f/10.0)
        end
      end

      def getChapterInfoProcess(t)
        return t[0], nil, nil, nil
      end

      def getPages(doc, chapter)
        doc.css(PAGES_CSS).collect {
          |pagedoc|
          {:url=>pagedoc['href'], :num=>pagedoc.child.to_s.match(PAGES_REGEX)[1].to_i}
        }
      end

    end
  end
end
