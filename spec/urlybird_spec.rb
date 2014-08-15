require 'spec_helper'

describe UrlyBird do

  let(:klass) { UrlyBird }

  describe '#seek' do
    let(:content) do
      <<-EOS.undent
        <a href="http://urlybird.com/search?q=wormy&amp;ie=UTF-8">Wormy</a>
        http://urlybird.com/search?q=urly&ie=latin1
      EOS
    end

    context 'when no block is passed' do
      subject { UrlyBird.seek(content) }

      it 'content is returned without modifications' do
        subject.should == content
      end
    end # no transforms

    context 'when no transforms are specified' do
      subject do
        UrlyBird.seek(content) { |url| }
      end

      it 'content is returned without modifications' do
        subject.should == content
      end
    end # no transforms

    describe 'URL Matching' do
      context 'when given syntactically correct but technically invalid ' +
        'URLs' do
        let(:content) { 'Wormy : http://www.not-so-urlybird.com/' }

        it 'the invalid URL match is silently skipped' do
          matched = []
          klass.seek(content) { |url| matched << url.to_s }
          matched.should == ['http://www.not-so-urlybird.com/']
        end
      end # given syntactically correct but technically invalid URLs

      context 'when some input URLs separates query params with "&amp;"' do
        let(:content) do
          <<-EOS.undent
            <a href="http://urlybird.com/search?q=wormy&amp;ie=UTF-8">Do It</a>
            http://urlybird.com/search?q=wormy&ie=UTF-8
          EOS
        end

        it 'query values are parsed correctly' do
          klass.seek(content) do |url|
            url.query_values.should == {'q' => 'wormy', 'ie' => 'UTF-8'}
          end
        end
      end # query params separted by "&amp;"

      context 'when input has oddly formatted anchor tags' do
        let(:content) do
          "< a href=\"http://urlybird.com/search?q=wormy&amp;ie=UTF-8\">\n" +
          "  Do It\n" +
          "</a>\n" +
          "<\n" +
          "  a\n" +
          "  class=\"foo\"\n" +
          "  href=\"http://urlybird.com/search?q=wormy&amp;ie=UTF-8\">\n" +
          "  Do It\n" +
          "</a>\n" +
          "http://urlybird.com/search?q=wormy&ie=UTF-8"
        end

        it 'query values are parsed correctly' do
          matched = []
          klass.seek(content) { |url| matched << url.to_s }
          matched.should == [
            'http://urlybird.com/search?q=wormy&ie=UTF-8',
            'http://urlybird.com/search?q=wormy&ie=UTF-8',
            'http://urlybird.com/search?q=wormy&ie=UTF-8',
          ]
        end
      end

      context 'when input anchors have non-href attributes with URL-like ' +
              'values' do
        let(:content) do
          <<-EOS.undent
            <a style="padding: 4px; color: black;" href="http://urlybird.com/">
              Do It
            </a>
          EOS
        end

        it 'only URL-like values within the href attribute is matched' do
          matched = []
          klass.seek(content) { |url| matched << url.to_s }
          matched.should == ['http://urlybird.com/']
        end
      end

      describe 'anchors_only option' do
        it 'defaults to false' do
          klass.send(:default_opts)[:anchors_only].should be false
        end

        context 'when set to true' do
          it 'only anchored URLs are matched' do
            matched = []
            klass.seek(content, :anchors_only => true) do |url|
              matched << url.to_s
            end
            matched.should == ['http://urlybird.com/search?q=wormy&ie=UTF-8']
          end
        end # match anchored only

        context 'when set to false' do
          it 'only anchored URLs are matched' do
            matched = []
            klass.seek(content, :anchors_only => false) { |url| matched << url.to_s }
            matched.should == [
              'http://urlybird.com/search?q=wormy&ie=UTF-8',
              'http://urlybird.com/search?q=urly&ie=latin1'
            ]
          end
        end # match anchored only
      end # anchors_only option

      describe 'scheme option' do
        let(:urls) do
          [ 'http://www.urlybird.com/', 'https://www.urlybird.com/',
            'ftp://www.urlybird.com/', 'ssh://www.urlybird.com/',
            'mailto:foo@urlybird.com' ]
        end

        let(:content) { urls.join("\n") }

        context 'when not given' do
          it 'any scheme is matched' do
            matched = []
            klass.seek(content) { |url| matched << url.to_s }
            matched.should == urls
          end
        end # when not given

        context 'when given' do
          it 'only URLs of specified schemes are matched' do
            matched = []
            klass.seek(content, :scheme => ['http', 'mailto']) do |url|
              matched << url.to_s
            end
            matched.should == urls.select do |item|
              item.match(/^(http\:|mailto\:)/)
            end
          end
        end # when given
      end # scheme option

      describe 'extname option' do
        let(:urls) do
          [ 'http://urlybird.com/foo.php', 'http://adobe.com/foo.cfm',
            'http://lolcats.com/lol.jpg', 'http://lolcats.com/lol.png' ]
        end

        let(:content) { urls.join("\n") }

        context 'when not given' do
          it 'no extension-based filtering is performed' do
            matched = []
            klass.seek(content) { |url| matched << url.to_s }
            matched.should == urls
          end
        end

        context 'when given' do
          it 'only URLs with matching extensions are matched' do
            matched = []
            klass.seek(content, :extname => /^(?!jpg|png|gif)/) do |url|
              matched << url.to_s
            end
            matched.should == urls.reject do |item|
              item.match(/\.(jpg|png)$/)
            end
          end
        end
      end # extname option

      describe 'host option' do
        let(:urls) do
          [ 'http://www.urlybird.com/', 'https://images.urlybird.com/',
            'http://www.not-so-urlybird.com/foo', 'http://wormy.co.uk/' ]
        end

        let(:content) { urls.join("\n") }

        context 'when not given' do
          it 'any host is matched' do
            matched = []
            klass.seek(content) { |url| matched << url.to_s }
            matched.should == urls
          end
        end # when not given

        context 'when given' do
          it 'only URLs of specified hosts are matched' do
            matched = []
            klass.seek(content, :host => /wormy\.com/) do |url|
              matched << url.to_s
            end
            matched.should == urls.select do |item|
              item.match(/wormy\.com/)
            end
          end

          context 'when input contains URLs of various schemes/types' do
            let(:urls) do
              [ 'http://www.urlybird.com/',  'http://www.wormy.com/',
                'https://www.urlybird.com/', 'https://www.wormy.com/',
                'ftp://www.urlybird.com/',   'ftp://www.wormy.com/',
                'ssh://www.urlybird.com/',   'ssh://www.wormy.com/',
                'mailto:foo@urlybird.com',   'mailto:foo@wormy.com' ]
            end

            let(:content) { urls.join("\n") }

            it 'URLs matching specified host are matched' do
              matched = []
              klass.seek(content, :host => /urlybird\.com/) do |url|
                matched << url.to_s
              end
              matched.should == urls.reject do |item|
                item.match(/wormy\.com\/$/)
              end
            end
          end # when input contains non-http/https URLs
        end # when given
      end # host option
    end # URL matching

    describe 'URL Manipulation' do
      context 'when manipulating URLs within anchor tags' do
        let(:content) do
          <<-EOS.undent
            <a href="http://urlybird.com/search?q=wormy&amp;ie=UTF-8">Do It</a>
            http://urlybird.com/search?q=wormy&ie=UTF-8
          EOS
        end
        it 'should escape ampersands (&) to "&amp;"' do
          result = klass.seek(content) { |url| }
          lines = result.split("\n")
          lines[0].should include('?q=wormy&amp;ie=UTF-8')
          lines[1].should include('?q=wormy&ie=UTF-8')
        end
      end

      context 'when injecting query params' do
        context 'into URLs without any params' do
          let(:content) do
            <<-EOS.undent
              http://www.urlybird.com/
              http://www.urlybird.com/
            EOS
          end

          it 'the query params are added' do
            result = klass.seek(content) do |url|
              url.query_values = (url.query_values || {}).merge(:foo => 'bar')
            end
            query_strings = result.split("\n").inject([]) do |result, item|
              result << item.split('?').last
            end
            query_strings.each do |string|
              string.should == 'foo=bar'
            end
          end
        end # without any params

        context 'into URLs with existing params' do
          let(:content) do
            <<-EOS.undent
              http://www.urlybird.com/search?q=wormy&ie=UTF-8
              http://www.urlybird.com/search?q=urly&ie=latin1
            EOS
          end

          it 'the query params are added' do
            result = klass.seek(content) do |url|
              url.query_values = (url.query_values || {}).merge(:foo => 'bar')
            end
            query_strings = result.split("\n").inject([]) do |result, item|
              result << item.split('?').last
            end
            query_strings[0].should include('q=wormy', 'ie=UTF-8', 'foo=bar')
            query_strings[1].should include('q=urly', 'ie=latin1', 'foo=bar')
          end
        end # with existing params

        context 'with dollar signs in their values' do
          let(:content) do
            <<-EOS.undent
              http://www.urlybird.com/search?q=wormy&amp;woo=$$boo$$
              http://www.urlybird.com/search?q=urly&woo=$$boo$$
            EOS
          end

          it 'the dollar signs are urlencoded properly' do
            result = klass.seek(content, :encode => true) do |url|
              new_query = (url.query_values || {}).merge(:foo => '$$bar$$')
              url.query_values = new_query
            end
            query_strings = result.split("\n").inject([]) do |result, item|
              result << item.split('?').last
            end
            query_strings[0].should include('q=wormy', 'woo=$$boo$$',
              'foo=$$bar$$')
            query_strings[1].should include('q=urly', 'woo=$$boo$$',
              'foo=$$bar$$')
          end
        end # with dollar signs
      end # injecting query params
    end # URL Manipulation
  end # seek

end # UrlyBird
