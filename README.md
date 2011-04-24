Version: 0.1.3

Manga Squirrel
----------------

[Manga Squirrel](http://github.com/Erol/manga-squirrel) is a background multi-threaded mass downloader for the site [Manga Fox](http://www.mangafox.com) using [Resque](http://github.com/defunkt/resque). It uses [Nokogiri](http://nokogiri.org) to scrape the site and curl to download the chapter image contents.

Installation
------------

### Redis

Manga Squirrel depends on [Resque] for background processing and thus requires the installation of Redis:

    $ wget http://redis.googlecode.com/files/redis-2.2.4.tar.gz
    $ tar xzf redis-2.2.4.tar.gz
    $ cd redis-2.2.4
    $ make
    $ make install

### Gem Installation

    $ gem install manga-squirrel

Usage
-----

Manga Squirrel requires a running local Redis server instance:

    $ redis-server

Before downloading, you will need to create a directory where the manga series and chapters will be stored and start the background workers which will download it:

    $ mkdir manga
    $ cd manga
    $ manga-squirrel workers --count=5
    
You may now add a manga to the download queue. You can add a single volume or chapter by:

    $ manga-squirrel queue naruto --volumes=1
    $ manga-squirrel queue naruto --chapters=2
    
Or a range of volumes or chapters:

    $ manga-squirrel queue naruto --volumes=3..4
    $ manga-squirrel queue naruto --chapters=5..6
    
Or a list of volumes or chapters:

    $ manga-squirrel queue naruto --volumes=[7,8,9]
    $ manga-squirrel queue naruto --chapters=[10,11,12]

You can monitor the progress of the background download queue by running resque-web:

    $ resque-web
    
And looking at the manga-squirrel queue.

Feedback
--------

If you discover any issues or simply want to drop a line, you can email me at:

erol.fornoles@gmail.com 

Copyright (c) 2011 Erol Fornoles, released under the MIT license