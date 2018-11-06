require 'iolaus/handlers/throttle'

RSpec.describe(Iolaus::Handlers::Throttle) do
  subject { described_class.instance }

  it 'registers its self as a Typhoeus.before handler' do
    handler = subject.method(:handle_before)

    expect(Typhoeus.before).to include(handler)
  end

  context 'when multiple wait timers are set on the same hostname within a short period' do
    it 'creates a single timer' do
      retry_time = (Time.now + 1.0)
      timer1 = subject.set_timer('foo.test', retry_time)
      timer2 = subject.set_timer('foo.test', retry_time)

      expect(timer1).to eq(timer2)
    end
  end
end
