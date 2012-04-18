require 'rubygems'
require 'thor'
require 'resque'
require 'yaml'
require 'net/http'
require 'uri'
require 'progressbar'
require 'manga-squirrel/common'
require 'manga-squirrel/queuer'
require 'manga-squirrel/config'
require 'manga-squirrel/series'
require 'pp'

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

      desc 'bundle [ --file=name --force=false --daemon=false]', 'Builds comic book archives for all new chapters for all the series listed in filename'
      method_option :file, :default=> "~/.ms"
      method_option :force, :default => false
      method_option :daemon, :default => false
      def bundle()

        $isDaemon = options[:daemon]
        $log = []

        Manga::Squirrel::ConfigFile.parse(options[:file]) do
          |name, series, raw, out, volume, chapter, cbf, finished|
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

        puts "-" * 50
        puts "Queued:"
        $log.each do
          |chapter|
          puts "#{chapter[:series]}> #{chapter[:chapter]} - #{chapter[:caption]}"
        end
      end

      desc 'fetch [ --file=name --daemon=false ]', 'Tries to fetch all series listed in filename, skipping any chapters already existing'
      method_option :file, :default => "~/.ms"
      method_option :daemon, :default => false
      def fetch

        $isDaemon = options[:daemon]
        $log = []

        Manga::Squirrel::ConfigFile.parse(options[:file]) do
          |name, series, raw, out, volume, chapter, cbf, finished|
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

        puts "-" * 50
        puts "Queued:"
        $log.each do
          |chapter|
          puts "#{chapter[:series]}> #{chapter[:chapter]} - #{chapter[:caption]}"
        end
      end

      desc 'fsck series [ --site=site --raw=raw --daemon=false ]', '**SLOW** Looks for missing chapters + pages'
      method_option :site, :default => 'MangaFox'
      method_option :raw, :default => '.'
      method_option :daemon, :default => false
      def fsck(series)
        $isDaemon = options[:daemon]
        site = "Manga::Squirrel::#{options[:site]}Series".to_class
        raw = File.expand_path options[:raw]
        s = site.new :name=>series.sanitize, :root=>raw
        s.all = true

        expectedChapters = s.chapters
        actualChapters = {}

        numMissingChapters = 0
        numMissingImages = 0

        pbar = ProgressBar.new("fsck",expectedChapters.count) unless $isDaemon
        #Assume expectedChapters has all of them (Dangerous assumption with scanlations, but hey)
        expectedChapters.values.reverse.each {
          |expectedChapter|
          isMissing = false

          pbar.inc unless $isDaemon
          path = gendir(raw, expectedChapter)
          puts "Testing #{expectedChapter[:chapter]} at #{path}"
          if !File.directory? path then
            puts ">>Missing chapter #{expectedChapter[:chapter]}"
            numMissingChapters += 1
            isMissing = true
          else
            expectedChapter[:pages].each {
              |page|
              i = 1
              begin
                url, ext = processDownload page, {:chapter=>{:img_div=>site::IMG_DIV}}
                uri = URI(URI.encode url)
                expectedSize = 0
                i = i + 1
                Net::HTTP.start(uri.host, uri.port) do
                  |http|
                  request = http.request_head(URI.encode url)
                  expectedSize = request['content-length'].to_i
                end
              rescue Timeout::Error
                puts "!Stalling due to network"
                sleep i
                continue if i > 10
                retry
              end
              expectedPath = File.join(path, "#{outNum(page[:num])}#{ext}")
              if File.exists? expectedPath then
                actualSize = File.size(expectedPath).to_i
              else
                actualSize = 0
              end
              puts "Checking page #{page[:url]} image #{url} size #{actualSize} expecting #{expectedSize}"
              unless actualSize == expectedSize then
                puts ">>Missing  page #{expectedChapter[:chapter]}: #{page[:num]}" unless actualSize > 0
                puts ">>Corrupt page #{expectedChapter[:chapter]}: #{page[:num]} (#{actualSize} of #{expectedSize})" if actualSize > 0
                numMissingImages += 1
                isMissing = true
                break
              end
            }
          end

          Queuer.queueChapter expectedChapter, raw if isMissing
        }
        pbar.finish unless $isDaemon

        puts "Summary Statistics"
        puts "------------------"
        puts "Missing Chapters: #{numMissingChapters}"
        puts "Missing Images: #{numMissingImages}"
      end
    end
  end
end
