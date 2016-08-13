require 'rubygems'
require './epub_book'

url,book_name = ARGF.argv


exit 1 if url.nil?

epub_book = EpubBook.new(url) do |book|
  #book.limit = 5
  book.cover_css = '.pic_txt_list .pic img'
  book.description_css = '.pic_txt_list p.description'
  book.title_css = '.pic_txt_list h3 span'
  book.index_item_css = 'ul.list li.c3 a'
  book.body_css = '.wrapper #content'
end

epub_book.generate_book(book_name)
