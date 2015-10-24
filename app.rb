# 
# docs:
# sinatra: http://www.sinatrarb.com/
# nokogiri: http://www.nokogiri.org/
#

require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'uri'
require 'net/http'

set :public_folder, File.dirname(__FILE__) + '/public'
set :static, true
set :protection, :except => [:json_csrf]

enable :logging

get '/' do
  erb :index
end

def validate(url)
  url =~ /^https?:\/\/((.{2,3})\.youtube\.com|youtu\.be)\//
end

get '/get-audio-stream' do
  url = params['url']
  if not validate(url)
    halt 500
  end
  youtubeDl = IO.popen [
    "youtube-dl",
    "-g",
    "--format",
    "bestaudio",
    "#{url}"
  ]
  audioLink = youtubeDl.readlines.join
  youtubeDl.close
  if $? != 0
    status 500
  else
    puts "requesting #{audioLink}"
    uri = URI::parse audioLink
    stream do |out|
      Net::HTTP.get_response(uri) do |res|
        res.read_body { |chunk|
          out << chunk
        }
        out.close
      end
    end
  end
end

get '/get-related' do
  url = params['url']
  if not validate(url)
    halt 500
  end
  html_doc = Nokogiri::HTML(open(url)) do |config|
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
