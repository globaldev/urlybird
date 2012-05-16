require 'uri'
require 'addressable/uri'

module UrlyBird

  def self.seek(content, opts={}, &block)

    opts = default_opts.merge(opts)

    # find URI matches within a set of schemes (e.g. ['http','mailto']) if
    # provided, nil will return all schemes
    content.gsub(regexp(opts)) do |matched|
      # capture the first captured part in case we're working with a anchor
      # tag
      url_raw = $1

      # check if the current URL is within an anchor
      is_anchor = !!matched.match(/^<\s*a/)

      # if we're not dealing with an anchored URL the whole string match is
      # the raw URL
      url_raw = matched unless is_anchor

      begin
        # create an Addressable::URI object, un-escaping "&amp;" if the URL is
        # within an anchor tag
        url = Addressable::URI.parse(
          is_anchor ? url_raw.gsub('&amp;', '&') : url_raw)

        if block_given? && valid?(url, opts)

          # yield valid URLs
          block.call(url)

          # turn URL back into a string and clone the string due to what seems
          # like internal string caching in Addressable
          url = url.to_s.clone

          # FIXME: Temporary fix to dealing with dollar signs ($) in URLs
          # which in most use cases are required as placeholders
          # and need to remain unencoded
          #
          # Ideally UrlyBird should provide some form of option to unencode
          # specific characters, or simply forcing developers to deal with
          # these kinds of special cases in their apps.
          url.gsub!('%24', '$')

          # escape ampersands (&) in anchor tag URLs
          url.gsub!(/&(?!amp;)/, '&amp;') if is_anchor

          # if we're working with an anchor tag inject the new URL, otherwise
          # just return the new URL as is
          is_anchor ? matched.gsub(url_raw, url) : url
        else
          matched
        end
      rescue Addressable::URI::InvalidURIError
        matched
      end
    end

  end

  private

  def self.default_opts
    { :anchors_only => false }
  end

  def self.valid?(url, opts)
    # validate extname regexp if provided
    return false if opts[:extname] && !url.extname.empty? &&
      url.extname.delete('.').match(opts[:extname]).nil?

    # validate host regexp if provided
    return false if opts[:host] && !url.host.to_s.empty? &&
      url.host.match(opts[:host]).nil?

    # return
    true
  end

  def self.uri_regexp(opts = {})
    /(#{URI.regexp(opts[:scheme])})/
  end

  def self.anchor_uri_regexp(opts = {})
    /<\s*a\s+[^>]*href\s*=\s*[\"']?(#{uri_regexp(opts)})[\"' >]/
  end

  def self.regexp(opts = {})
    url_match = uri_regexp(opts)
    anchors   = anchor_uri_regexp(opts)
    any       = /#{anchors}|#{url_match}/
    opts[:anchors_only] ? anchors : any
  end

end
