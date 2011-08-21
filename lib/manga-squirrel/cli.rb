require 'rubygems'
require 'thor'
require 'resque'
require 'yaml'
require 'manga-squirrel/common'
require 'manga-squirrel/queuer'

module Manga
  module Squirrel
    class CLI < Thor
      desc 'worker', 'Starts a manga-squirrel worker.'
      def worker
        worker = Resque::Worker.new('manga-squirrel')
        worker.verbose = true
        worker.log "Starting Worker #{worker}"

        worker.work(5)
      end

      desc 'workers [ --count=number ]', 'Starts a pool of manga-squirrel worker. The default number is 5.'
      method_option :count, :default => 5
      def workers
        threads = []

        options[:count].to_i.times do
          threads << Thread.new do
            system "manga-squirrel worker"
          end
        end

        threads.each { |thread| thread.join }    
      end

      desc 'bundle series [--force=false --out=dir]', 'Builds CBZs for all new chapters for the specified series name, unless forced'
      method_option :out, :default => "."
      method_option :force, :default => false
      def bundle(series)
        Queuer.queueBundle, {:series=>series.strip, :options=>{:out=>File.expand_path(options[:out]), :force=>options[:force]}}
      end

      desc 'fetch [--file=name]', 'Tries to fetch all series listed in filename, skipping any chapters already existing'
      method_option :file, :default => "~/.ms"
      def fetch
        Manga::Squirrel::ConfigFile.parse(options[:file]).each do
          |name, site, raw, out, autocbz, volume, chapter|
          puts "Fetching #{name]} from #{site}"
          begin
            Queuer.queueDownload, [:site=>site, :series=>name, :options=>{:raw=>raw, :out=>out, :autocbz=>autocbz, :volume=>volume, :chapter=>chapter}]
          rescue
            #  puts "ERROR: Failed to fetch #{name}\n#{$0} #{$.}: #{$!}"
          end
        end
        f.close
      end

      desc 'fsck series [--site=site]', '**SLOW** Looks for missing chapters + pages'
      method_option :site, :default => 'MangaFox'
      def fsck(series)
        site = ("Manga::Squirrel::"+options[:site]).to_class
        expectedChapters = site::getChapters(series, {:volumes=>"true",:chapters=>"true"},{})
        actualChapters = Array.new
        Dir.glob(File.join(series,"*")).each {
          |chapter|
          info = revgendir(chapter)
          actualChapters[info[:chapter]] = info
        }

        numMissingChapters = 0
        numMissingImages = 0

        #Assume expectedChapters has all of them (Dangerous assumption with scanlations, but hey)
        expectedChapters.each {
          |expectedChapter|
          if actualChapters[expectedChapter[:chapter].to_f].nil? then
            puts "Missing chapter #{expectedChapter[:chapter]}"
            self.makequeue QueueAction::Download, {:site=>site, :series=>series, :options=>{:volumes=>"true",:chapters=>expectedChapter[:chapter].to_f}}
            numMissingChapters += 1
          else
            actualImages = Dir.entries(gendir(expectedChapter)).reject{|entry| entry == "." || entry == ".."}
            expectedChapter[:pages].each {
              |ip|
              if actualImages.include?(ip[1]+"")
              end
            }
          end
        }

        puts "Summary Statistics"
        puts "------------------"
        puts "Missing Chapters: #{numMissingChapters}"
        puts "Missing Images: #{numMissingImages}"
      end
    end
  end
end
