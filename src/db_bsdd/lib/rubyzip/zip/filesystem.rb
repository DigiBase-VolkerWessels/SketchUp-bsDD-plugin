# frozen_string_literal: true

require 'zip'
require_relative 'filesystem/zip_file_name_mapper'
require_relative 'filesystem/directory_iterator'
require_relative 'filesystem/dir'
require_relative 'filesystem/file'

module BimTools
 module Zip
  # The ZipFileSystem API provides an API for accessing entries in
  # a zip archive that is similar to ruby's builtin File and Dir
  # classes.
  #
  # Requiring 'zip/filesystem' includes this module in BimTools::Zip::File
  # making the methods in this module available on BimTools::Zip::File objects.
  #
  # Using this API the following example creates a new zip file
  # <code>my.zip</code> containing a normal entry with the name
  # <code>first.txt</code>, a directory entry named <code>mydir</code>
  # and finally another normal entry named <code>second.txt</code>
  #
  #   require_relative 'zip/filesystem'
  #
  #   BimTools::Zip::File.open("my.zip", create: true) {
  #     |zipfile|
  #     zipfile.file.open("first.txt", "w") { |f| f.puts "Hello world" }
  #     zipfile.dir.mkdir("mydir")
  #     zipfile.file.open("mydir/second.txt", "w") { |f| f.puts "Hello again" }
  #   }
  #
  # Reading is as easy as writing, as the following example shows. The
  # example writes the contents of <code>first.txt</code> from zip archive
  # <code>my.zip</code> to standard out.
  #
  #   require_relative 'zip/filesystem'
  #
  #   BimTools::Zip::File.open("my.zip") {
  #     |zipfile|
  #     puts zipfile.file.read("first.txt")
  #   }
  module FileSystem
    def initialize # :nodoc:
      mapped_zip       = ZipFileNameMapper.new(self)
      @zip_fs_dir      = Dir.new(mapped_zip)
      @zip_fs_file     = File.new(mapped_zip)
      @zip_fs_dir.file = @zip_fs_file
      @zip_fs_file.dir = @zip_fs_dir
    end

    # Returns a FileSystem::Dir which is much like ruby's builtin Dir (class)
    # object, except it works on the BimTools::Zip::File on which this method is
    # invoked
    def dir
      @zip_fs_dir
    end

    # Returns a FileSystem::File which is much like ruby's builtin File
    # (class) object, except it works on the BimTools::Zip::File on which this method is
    # invoked
    def file
      @zip_fs_file
    end
  end

  class File
    include FileSystem
  end
 end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
