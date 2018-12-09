RSpec.describe YeelightCli do
  let(:socket) { double(:socket) }
  let(:multicast_address) { double(:multicast_address) }
  let(:multicast_port) { double(:multicast_port) }
  let(:discover_timeout_sec) { double(:discover_timeout_sec) }
  let(:socket_response_max_length) { double(:socket_response_mac_length) }

  let(:package_1) { double(:package_1) }
  let(:package_2) { double(:package_2) }

  let(:initialize_from_package_proc) { double(:initialize_from_package_proc) }

  let(:bulb_1) { double(:bulb_1) }
  let(:bulb_2) { double(:bulb_2) }

  let(:main_bulb_group) { double(:main_bulb_group) }
  let(:bulb_group_1) { double(:bulb_group_1) }

  before do
    expect(socket).to receive(:send)
      .with(
        described_class::DISCOVER_PAYLOAD,
        0,
        multicast_address,
        multicast_port
      )

    allow(described_class)
      .to receive(:collect_packages)
      .with(discover_timeout_sec, socket, socket_response_max_length)
      .and_return([package_1, package_2])

    allow(described_class::Bulb).to receive(:initialize_from_package)
      .with(package_1)
      .and_return(bulb_1)

    allow(described_class::Bulb).to receive(:initialize_from_package)
      .with(package_2)
      .and_return(bulb_2)

    allow(bulb_1).to receive(:group_name).with(1).and_return(:group_1)
    allow(bulb_2).to receive(:group_name).with(1).and_return(:group_1)
    allow(bulb_1).to receive(:group_name).with(2)
    allow(bulb_2).to receive(:group_name).with(2)

    allow(described_class::BulbGroup)
      .to receive(:new)
      .with(name: 'main')
      .and_return(main_bulb_group)

    allow(described_class::BulbGroup)
      .to receive(:new)
      .with(name: :group_1)
      .and_return(bulb_group_1)

    expect(bulb_group_1).to receive(:<<)
      .with([bulb_1, bulb_2])

    expect(main_bulb_group).to receive(:<<)
      .with(bulb_group_1)
  end

  describe '.discover' do
    let(:call_method) do
      described_class.discover(
        socket: socket,
        multicast_address: multicast_address,
        multicast_port: multicast_port,
        discover_timeout_sec: discover_timeout_sec,
        socket_response_max_length: socket_response_max_length
      )
    end

    it 'returns the main group' do
      expect(call_method).to be main_bulb_group
    end
  end

  describe '.discover!' do
    let(:call_method) do
      described_class.discover!(
        socket: socket,
        multicast_address: multicast_address,
        multicast_port: multicast_port,
        discover_timeout_sec: discover_timeout_sec,
        socket_response_max_length: socket_response_max_length
      )
    end

    context 'the main group is not empty' do
      before do
        allow(main_bulb_group).to receive(:none?).and_return(false)
      end

      it 'returns the main group' do
        expect(call_method).to be main_bulb_group
      end
    end

    context 'the main group is empty' do
      before do
        allow(main_bulb_group).to receive(:none?).and_return(true)
      end

      it 'raises the error' do
        expect { call_method }.to raise_error('No bulbs have been found')
      end
    end
  end
end
