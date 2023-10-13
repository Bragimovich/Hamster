module Hamster
  RSpec.describe Scraper::Dasher do
    let(:test_pdf) {"#{RSPEC_ROOT}/support/fixtures/test.pdf"}

    describe '#connect, #connection' do
      it 'should be create Faraday connection' do
        cobble = described_class.new(using: :cobble)
        expect(cobble.connection).to be_nil
        
        cobble.connect
        expect(cobble.connection).not_to be_nil
        expect(cobble.connection.class).to equal(Faraday::Connection)
      end

      it 'should be create Mechanize connection' do
        crowbar = described_class.new(using: :crowbar)
        expect(crowbar.connection).to be_nil

        crowbar.connect
        expect(crowbar.connection).not_to be_nil
        expect(crowbar.connection.class).to equal(Mechanize)
      end

      it 'should be create Ferrum connection' do
        hammer = described_class.new(using: :hammer, pc: 1, headless: true)
        expect(hammer.connection).to be_nil
        
        hammer.connect
        expect(hammer.connection).not_to be_nil
        expect(hammer.connection.class).to equal(Ferrum::Browser)
        hammer.close
      end
    end

    describe '#get' do
      context 'when connection is Faraday' do
        let(:cobble) { described_class.new(using: :cobble) }

        before do
          cobble.connect
        end

        it 'should be get 200 response body' do
          body = cobble.get('https://api.github.com')
          expect(body).to include('Hello world!')
        end
      end

      context 'when connection is Mechanize' do
        let(:crowbar) { described_class.new(using: :crowbar) }

        before do
          crowbar.connect
        end

        it 'should be get 200 response body' do
          body = crowbar.get('https://api.github.com')
          expect(body).to include('Hello world!')
        end
      end

      context 'when connection is Ferrum' do
        let(:hammer) { described_class.new(using: :hammer) }

        before do
          hammer.connect
        end

        after do
          hammer.close
        end

        it 'should get 200 response body' do
          body = hammer.get('https://api.github.com')
          expect(body).to include('current_user_url')
        end
      end
    end

    describe '#post' do
      let(:params) {
        {first_name: 'A', last_name: 'A'}
      }
      
      context 'when connection is Faraday' do
        let(:cobble) { described_class.new(using: :cobble, req_body: params.map { |key, val| "#{CGI.escape(key.to_s)}=#{CGI.escape(val)}" }.join('&')) }

        before do
          cobble.connect
        end

        it 'should be get 200 response body' do
          body = cobble.post('https://api.cobble.com')
          expect(body).to include('Hello world!')
        end
      end

      context 'when connection is Mechanize' do
        let(:crowbar) { described_class.new(using: :crowbar, query: params) }

        before do
          crowbar.connect
        end

        it 'should be returns body' do
          body = crowbar.post('https://api.crowbar.com')
          expect(body).to include('Hello world!')
        end
      end
    end

    describe '#get_file' do
      before(:each) do
        stub_request(:get, 'https://api.dasher.com/test.pdf').
          to_return(status: 200, body: File.read(test_pdf, mode: 'rb'), headers: {content_type: 'application/pdf'})
      end
      context 'when connection is Faraday' do
        let(:cobble) { described_class.new(using: :cobble) }
        
        it 'should get file' do
          File.delete("#{cobble.storehouse}/store/test.pdf") if File.exist?("#{cobble.storehouse}/store/test.pdf")

          cobble.get_file('https://api.dasher.com/test.pdf')
          expect(File).to exist("#{cobble.storehouse}/store/test.pdf")
        end
      end

      context 'when connection is Mechanize' do
        let(:crowbar) { described_class.new(using: :crowbar) }
        
        it 'should be returns body' do
          File.delete("#{crowbar.storehouse}/store/test.pdf") if File.exist?("#{crowbar.storehouse}/store/test.pdf")

          crowbar.get_file('https://api.dasher.com/test.pdf')
          expect(File).to exist("#{crowbar.storehouse}/store/test.pdf")
        end
      end
    end

    describe '#close' do
      context 'when connection is Faraday' do
        let(:cobble) { described_class.new(using: :cobble) }
        
        it 'should be close cobble connection' do
          cobble.connect
          expect(cobble.connection).not_to be_nil

          cobble.close
          expect(cobble.connection).to be_nil
        end
      end

      context 'when connection is Mechanize' do
        let(:crowbar) { described_class.new(using: :crowbar) }
        
        it 'should be close crowbar connection' do
          crowbar.connect
          expect(crowbar.connection).not_to be_nil

          crowbar.close
          expect(crowbar.connection).to be_nil
        end
      end

      context 'when connection is Ferrum' do
        let(:hammer) { described_class.new(using: :hammer) }
        
        it 'should be close hammer connection' do
          hammer.connect
          expect(hammer.connection).not_to be_nil

          hammer.close
          expect(hammer.connection).to be_nil
        end
      end
    end

    describe '#current_proxy' do
      context 'when connection is Faraday' do
        let(:cobble) { described_class.new(using: :cobble) }
        
        it 'should be return proxy of cobble connection' do
          expect(cobble.current_proxy).to be_nil

          cobble.connect
          expect(cobble.current_proxy).not_to be_nil

          cobble.close
          expect(cobble.current_proxy).to be_nil
        end
      end

      context 'when connection is Mechanize' do
        let(:crowbar) { described_class.new(using: :crowbar) }
        
        it 'should be return proxy of crowbar connection' do
          expect(crowbar.current_proxy).to be_nil

          crowbar.connect
          expect(crowbar.current_proxy).not_to be_nil

          crowbar.close
          expect(crowbar.current_proxy).to be_nil
        end
      end

      context 'when connection is Ferrum' do
        let(:hammer) { described_class.new(using: :hammer) }
        
        it 'should be return proxy of hammer connection' do
          expect(hammer.current_proxy).to be_nil

          hammer.connect
          expect(hammer.current_proxy).not_to be_nil

          hammer.close
          expect(hammer.current_proxy).to be_nil
        end
      end
    end
  end
end