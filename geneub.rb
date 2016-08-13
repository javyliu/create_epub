#!/usr/bin/env ruby
require 'rubygems'
require 'eeepub'

dir = File.join(File.dirname(__FILE__), 'files')
epub = EeePub.make do
  title       'sample'
  creator     'javy_liu'
  publisher   'javy_liu'
  date        Time.now
  identifier  'http://javy_liu.com/book/', :scheme => 'URL'
  uid         'http://javy_liu.com/book/'

  files [File.join(dir,'25-7243.html'), File.join(dir,'25-7249.html')] # or files [{'/path/to/foo.html' => 'dest/dir'}, {'/path/to/bar.html' => 'dest/dir'}]
  nav [
    {:label => '1. foo', :content => '25-7243.html', :nav => [
      {:label => '1.1 foo-1', :content => '25-7243.html#content'}
    ]},
    {:label => '1. bar', :content => '25-7249.html'}
  ]
end
epub.save('sample.epub')
