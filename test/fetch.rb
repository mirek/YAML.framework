# http://yaml.kwiki.org/index.cgi?YamlTestingSuiteFetcher
# fetch_yts.rb (assumes Ruby >= 1.7.3)

require 'open-uri'
require 'cgi'

open('http://yaml.kwiki.org/index.cgi?YamlTestingSuiteIndex').read.scan(/"\/yamlwiki\/(Yts.*?)"/) do |yts|
  puts "Fetching #{yts[0]}"
  data = Net::HTTP::get
  URI::parse("#{wiki}/#{yts[0]}")
  File::open(yts[0], 'w') { |file|
    file.puts CGI::unescapeHTML( $1 )
  } if data =~ /<pre.*?>(.*?)\n<\/pre>/mi
end
