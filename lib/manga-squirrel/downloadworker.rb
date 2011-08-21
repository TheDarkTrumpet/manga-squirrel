require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'manga-squirrel/common'
require 'peach'

module Manga
  module Squirrel
    class Manga::Squirrel::DownloadWorker
      @queue  = 'manga-squirrel'

      def self.perform(action, chapter)
        Hash.transform_keys_to_symbols(chapter)[:pages].peach do
        |page|
          page = Hash.transform_keys_to_symbols(page)
          doc = Nokogiri::HTML(open(page[:url]))

          img = doc.css(chapter[:img_div]).attribute('src').value
          ext = img.gsub(/\.*(\.[^\.]*)$/).first

          FileUtils.mkdir_p dir = gendir(chapter)

          system 'curl', img, "-o", File.join(dir, "#{"%03d" % page[:num]}#{ext}")
        end
      end
    end
  end
end
