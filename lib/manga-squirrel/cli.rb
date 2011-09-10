require 'rubygems'
require 'thor'
require 'resque'
require 'yaml'
require 'manga-squirrel/common'
require 'manga-squirrel/queuer'
require 'manga-squirrel/config'

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

      desc 'bundle [--file=name --force=false]', 'Builds comic book archives for all new chapters for all the series listed in filename'
      method_option :file, :default=> "~/.ms"
      method_option :force, :default => false
      def bundle()
        Manga::Squirrel::ConfigFile.parse(options[:file]) do
          |name, series, raw, out, autocbz, volume, chapter, cbf, finished|
          puts "Bundling #{name}"
          begin
            Queuer.queueBundle :name=>name,
                               :series=>series,
                               :raw=>raw,
                               :out=>out,
                               :cbf=>cbf,
                               :force=>options[:force]
          #rescue
          #  puts "ERROR: Failed to bundle #{name}\n#{$0} #{$.}: #{$!}"
          end
        end
      end

      desc 'fetch [--file=name]', 'Tries to fetch all series listed in filename, skipping any chapters already existing'
      method_option :file, :default => "~/.ms"
      def fetch
        Manga::Squirrel::ConfigFile.parse(options[:file]) do
          |name, series, raw, out, autocbz, volume, chapter, cbf, finished|
          if finished then
            puts "Skipping #{name}"
          else
            puts "Fetching #{name} as a #{series}"
            begin
              Queuer.queueDownload :name=>name,
                                   :series=>series,
                                   :raw=>raw,
                                   :volume=>volume,
                                   :chapter=>chapter
            #rescue
            #   puts "ERROR: Failed to fetch #{name}\n#{$0} #{$.}: #{$!}"
            end
          end
        end
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
