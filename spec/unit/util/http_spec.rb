require 'iolaus/util/http'

RSpec.describe(Iolaus::Util::HTTP) do
  subject { Class.new{include Iolaus::Util::HTTP}.new }

  context 'when parsing Retry-After headers' do
    it 'parses integers' do
      result = subject.parse_retry_after_header('42')

      expect(result).to eq(42)
    end

    it 'parses RFC 2822 date strings' do
      result = subject.parse_retry_after_header('Wed, 13 Apr 2005 15:18:05 GMT')

      expect(result).to be_a(Time)
    end

    it 'returns nil when parsing something that is not an integer or RFC 2822 date' do
      result = subject.parse_retry_after_header('foo')

      expect(result).to be_nil
    end
  end

  context 'when computing retry_at dates' do
    it 'returns a Time instance when passed a RFC 2822 date and an integer' do
      result = subject.compute_retry_at('Wed, 13 Apr 2005 15:18:05 GMT', '10')

      expect(result).to be_a(Time)
    end

    it 'returns nil when passed nil and an integer' do
      result = subject.compute_retry_at(nil, '10')

      expect(result).to be_nil
    end

    it 'selects the maximum time from a list of integers' do
      expected = Time.rfc2822('Wed, 13 Apr 2005 15:18:25 GMT')
      result = subject.compute_retry_at('Wed, 13 Apr 2005 15:18:05 GMT', ['10', '20'])

      expect(result).to eq(expected)
    end

    it 'returns a Time when passed a RFC 2822 date and a RFC 2822 date' do
      result = subject.compute_retry_at('Wed, 13 Apr 2005 15:18:05 GMT',
                                        'Wed, 13 Apr 2005 15:18:25 GMT')

      expect(result).to be_a(Time)
    end

    it 'returns a Time when passed nil and a RFC 2822 date' do
      result = subject.compute_retry_at(nil, 'Wed, 13 Apr 2005 15:18:25 GMT')

      expect(result).to be_a(Time)
    end

    it 'selects the maximum time from a list of RFC 2822 dates' do
      expected = Time.rfc2822('Wed, 13 Apr 2005 15:18:25 GMT')
      result = subject.compute_retry_at('Wed, 13 Apr 2005 15:18:05 GMT',
                                        ['Wed, 13 Apr 2005 15:18:15 GMT',
                                         'Wed, 13 Apr 2005 15:18:25 GMT'])

      expect(result).to eq(expected)
    end

    it 'returns nil if passed a RFC 2822 date and nil' do
      result = subject.compute_retry_at('Wed, 13 Apr 2005 15:18:05 GMT', nil)

      expect(result).to be_nil
    end

    it 'returns nil if passed a RFC 2822 date and an uparsable date' do
      result = subject.compute_retry_at('Wed, 13 Apr 2005 15:18:05 GMT', 'foo')

      expect(result).to be_nil
    end
  end
end
