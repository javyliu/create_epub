require 'bundler/setup'
require 'open-uri'
require 'nokogiri'
require 'eeepub'
require 'pry'
require 'base64'

#index_url 书目录地址
#title_css 书名css路径
#index_item_css 目录页列表项目,默认 ul.list3>li>a
#body_css 内容css, 默认 .articlebody
#limit 用于测试时使用，得到页面的页数
#item_attr 目录页item获取属性 默认为 'href'
#page_css 分页css路径
#page_attr 分页链接地址属性
class EpubBook
  UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.116 Safari/537.36"
  Referer = "http://www.baidu.com/"
  attr_accessor :title_css, :index_item_css, :body_css, :limit, :item_attr, :page_css, :page_attr,:cover
  attr_accessor :cover_css, :description_css


  Reg = /<script.*?>.*?<\/script>/m

  def initialize(index_url, path: nil,ua: UserAgent, ref: Referer, creator: 'javy liu' )
    @index_url = index_url
    @user_agent = ua
    @referer = ref
    @folder_name =  Base64.urlsafe_encode64(index_url)[-10..-3]
    @book_path = path || File.join(File.dirname(__FILE__), @folder_name)
    @creator = creator
    @title_css = '.wrapper h1.title1'
    @index_item_css = 'ul.list3>li>a'
    @cover = 'cover.jpg'
    @body_css = '.articlebody'
    @item_attr = "href"
    @files = []
    yield self if block_given?
  end


  def link_host
    @link_host ||= @index_url[/\A(http:\/\/.*?)\/\w+/,1]
  end


  #创建书本
  def generate_book(book_name=nil)
    Dir.mkdir(@book_path) unless test(?d,@book_path)
    #获取epub源数据
    fetch_book
    if  !@cover_css && @cover
      generate_cover = <<-eof
        convert #{@cover} -font tsxc.ttf -gravity center -fill red -pointsize 16 -draw "text 0,0 '#{@title}'"  #{File.join(@book_path,@cover)}
      eof
      system(generate_cover)
      #@files.unshift({label: @title, content: @cover})
    end

    epub = EeePub.make

    epub.title @title
    epub.creator @creator
    epub.publisher @creator
    epub.date Time.now
    epub.identifier "http://javy_liu.com/book/#{@folder_name}", :scheme => 'URL'
    epub.uid "http://javy_liu.com/book/#{@folder_name}"
    epub.cover @cover
    epub.subject @title
    epub.description @description if @description
    epub.files @files.map{|item| File.join(@book_path,item[:content])}.push(File.join(@book_path,@cover))
    epub.nav @files


    epub.save("#{book_name || @folder_name}.epub")

  end

  private

  def fetch_book
    #binding.pry
    doc = Nokogiri::HTML(open(URI.encode(@index_url),"User-Agent" => @user_agent ,'Referer'=> @referer).read) rescue( puts($!.to_s) and return)

    @title = doc.css(@title_css).text.strip
    if @cover_css
      cover_url = doc.css(@cover_css).attr("src").to_s
      puts cover_url
      cover_url = link_host + cover_url unless cover_url.start_with?("http")
      system("curl #{cover_url} -o #{File.join(@book_path,@cover)} ")
    end
    if @description_css
      @description = doc.css(@description_css).text
    end
    puts @title

    doc.css(@index_item_css).each_with_index do |item,index|
      break if limit && index >= limit
      _href = URI.encode(item.attr(@item_attr).to_s)
      unless _href.start_with?("http")
        _href = link_host + _href
      end

      puts _href
      doc_file = Nokogiri::HTML(open(_href,"User-Agent" => @user_agent,'Referer'=> @referer).read) rescue( puts($!.to_s) and next)


      _basename = "#{index}.html"

      File.open(File.join(@book_path,_basename ),'w') do |f|
        f.write("<h3>#{item.text}</h3>")
        f.write(doc_file.css(@body_css).to_s.gsub(Reg,''))
      end

      @files.push({label: item.text.tap{|t|puts(t.inspect)}, content: _basename })
    end

    #如果有分页
    if @page_css && @page_attr
      @index_url = doc.css(@page_css).attr(@page_attr).to_s
      fetch_book
    end

  end

end

