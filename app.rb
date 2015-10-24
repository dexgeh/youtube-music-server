# 
# docs:
# sinatra: http://www.sinatrarb.com/
# nokogiri: http://www.nokogiri.org/
#

require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'

set :public_folder, File.dirname(__FILE__) + '/public'
set :static, true
set :protection, :except => [:json_csrf]

get '/' do
  erb :index
end

get '/get-audio-link' do
  url = params['url']
  youtubeDl = IO.popen [
    "youtube-dl",
    "-g",
    "--format",
    "bestaudio",
    "#{url}"
  ]
  audioLink = youtubeDl.readlines.join
  youtubeDl.close
  status 500 if $? != 0
  headers \
    "Content-Type" => "text/plain"
  body audioLink
end

get '/get-related' do
  html_doc = Nokogiri::HTML(open(params['url'])) do |config|
    config.nonet
  end
  related = html_doc.css("#watch-related>li")
  if not related
    status 500
    return
  end
  content_type :json
  related.map { |el|
    link = el.css(".content-wrapper>a")
    value = nil
    if link.first
      href = link.first["href"]
      title = el.css(".title")
      value = {
        :href => href,
        :title => title
      }
    end
    value
  }.select { |v| v }.to_json
end
