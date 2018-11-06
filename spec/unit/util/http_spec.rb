require 'iolaus/util/http'

RSpec.describe(Iolaus::Util::HTTP) do
  subject { Class.new{include Iolaus::Util::HTTP}.new }

  context 'when parsing Retry-After headers' do
    it 'parses integers' do
      result = subject.parse_retry_after_header('42')

      expect(result).to eq(42)
    end

    it 'returns 0 when parsing a RFC 2822 date that has passed' do
      result = subject.parse_retry_after_header('Wed, 13 Apr 2005 15:18:05 GMT')

      expect(result).to eq(0)
    end

    it 'returns nil when parsing something that is not an integer or RFC 2822 date' do
      result = subject.parse_retry_after_header('foo')

      expect(result).to eq(nil)
    end
  end
end
