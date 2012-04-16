require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'manga-squirrel/common'
require 'peach'

module Manga
  module Squirrel
    class Manga::Squirrel::DownloadWorker
      @queue  = 'manga-squirrel'

      def self.perform(options)
        options = Hash.transform_keys_to_symbols(options)
        Hash.transform_keys_to_symbols(options[:chapter])[:pages].peach do
        |page|
          page = Hash.transform_keys_to_symbols(page)

          #Get image url
          doc = Nokogiri::HTML(open(page[:url]))
          img = doc.css(options[:chapter][:img_div]).attribute('src').value
          ext = img.gsub(/\.*(\.[^\.]*)$/).first

          FileUtils.mkdir_p dir = gendir(options[:raw], options[:chapter])

          #Run curl to fetch
           system "curl --max-time 60 --retry 3 --speed-time 60 --speed-limit 0",  "-sS" , img, "-o", (File.join(dir, outNum(page[:num].to_i))+ext)
        end
      end
    end
  end
end
