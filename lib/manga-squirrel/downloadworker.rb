require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'manga-squirrel/common'
require 'shellwords'
require 'peach'
require 'uri'

module Manga
  module Squirrel
    class Manga::Squirrel::DownloadWorker
      @queue  = 'manga-squirrel'

      def self.perform(options)
        options = Hash.transform_keys_to_symbols(options)
        Hash.transform_keys_to_symbols(options[:chapter])[:pages].peach do
        |page|
          page = Hash.transform_keys_to_symbols(page)

          i = 1
          begin
            i = i + 1
            img, ext = processDownload page, options
          rescue
            sleep 1
            puts "!!!STALLED: #{$!}"
            retry if i < 10
          end

          FileUtils.mkdir_p dir = gendir(options[:raw], options[:chapter])
          out = File.join(dir, outNum(page[:num].to_i))+ext

          #Run curl to fetch
          puts "---Fetching #{img} to #{out}"
          cmd = "curl --max-time 60 --retry 3 --speed-time 60 --speed-limit 0 -sS #{URI.encode(img).shellescape} -o #{out.shellescape}"
          puts "--->Running #{cmd}"
          if !system cmd
            throw SystemFailedError
          end
        end
      end
    end
  end
end
