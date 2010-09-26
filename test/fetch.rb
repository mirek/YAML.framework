# Dump example files from http://www.yaml.org/spec/1.2/spec.html
require 'rubygems'
require 'open-uri'
require 'hpricot'

doc = open("http://www.yaml.org/spec/1.2/spec.html") { |f| Hpricot(f) }

doc.search("//div[@class='example']").each do |example|
  title = example.at("//p[@class='title']/b").to_plain_text
  yaml = example.at("//*[@class='database']").to_plain_text
  filename = "spec12-#{title.downcase.gsub(/[^a-zA-Z0-9]/, '-').gsub(/-+/, '-').gsub(/-+$/, '')}.yaml"
  puts filename
  open("yaml/#{filename}", 'w').write(yaml)
end
