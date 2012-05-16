$:.unshift(File.expand_path('../../lib',__FILE__))

require 'urlybird'

# Query parameters to append
params = {
  :q4 => 'four',
  :q5 => 'five',
  :q6 => 'six'
}

# HTML Content
html = <<-HTML
  <link rel="stylesheet" href="http://www.urlybird.com/style.css">
  <p>
    The urlybird gets the worm.
    http://www.urlybird.com?q1=one&amp;q2=two&amp;q3=three
    <a href="http://www.urlybird.com?q1=one&amp;q2=two&amp;q3=three">The</a>.
    <a href="http://www.urlybird.com?q1=one&q2=two&q3=three">urlybird</a>.
    <a href="http://www.not-so-urlybird.com?q1=one&amp;q2=two&amp;q3=three">gets</a>.
    <a href="mailto:bird@urlybird.com">the</a>.
    <img src="http://urlybird.com/images/worm.jpg" />
  </p>
HTML

# Plain text content
text = <<-TEXT
 http://www.urlybird.com?q1=one&q2=two&q3=three
 http://www.not-so-urly-bird.com?q1=one&q2=two&q3=three
 bird@urlybird.com
 http://urlybird.com/images/worm.jpg
TEXT

# Preferences
scheme = ['http','https']
host = /www\.urlybird\.com/
extname = /^((?!(css|jpg|jpeg|gif|png)).)*$/

# Usage example - HTML
new_html = UrlyBird.seek(html, :scheme => scheme, :host => host, :extname => extname, :anchors_only => false) do |url|
   url.query_values = (url.query_values.nil? ? params : url.query_values.merge(params))
end
p html
p new_html

# Usage example - Plain text
new_text = UrlyBird.seek(text, :scheme => scheme, :host => host, :extname => extname, :encode => false) do |url|
   url.query_values = (url.query_values.nil? ? params : url.query_values.merge(params))
end
p text
p new_text