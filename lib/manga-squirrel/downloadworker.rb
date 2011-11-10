require 'rubygems'
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
          imgurl = page[:url]
          ext = File.basename(imgurl).gsub(/\.*(\.[^\.]*)$/).first
          FileUtils.mkdir_p dir = gendir(options[:raw], options[:chapter])

          system "curl --max-time 60 --retry 3 --speed-time 60 --speed-limit 0 #{imgurl} -o #{File.join(dir, outNum(page[:num]))}#{ext}"
        end
      end
    end
  end
end
