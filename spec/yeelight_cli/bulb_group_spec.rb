RSpec.describe YeelightCli::BulbGroup do
  let(:bulb_1) { double(:bulb_1, name: :bulb_1, id: 1) }
  let(:bulb_2) { double(:bulb_2, name: :bulb_2, id: 2) }

  let(:subject) { described_class.new(name: :name, includes: [bulb_1, bulb_2]) }

  describe 'equality' do
    let(:bulb_group_1) do
      described_class.new(name: :name, includes: [bulb_1, bulb_2])
    end

    let(:bulb_group_2) do
      described_class.new(name: :another_name, includes: [bulb_1, bulb_2])
    end

    let(:bulb_group_3) do
      described_class.new(name: :name, includes: [bulb_1])
    end

    it 'resolves equality correctly' do
      expect(subject == bulb_group_1).to be true
      expect(subject == bulb_group_2).to be false
      expect(subject == bulb_group_3).to be false
    end
  end

  describe 'comparison' do
    let(:bulb_group_1) { described_class.new(name: :name) }
    let(:bulb_group_2) { described_class.new(name: :a) }
    let(:bulb_group_3) { described_class.new(name: :z) }

    it 'compares correctly' do
      expect(subject <=> bulb_group_1).to be 0
      expect(subject <=> bulb_group_2).to be 1
      expect(subject <=> bulb_group_3).to be(-1)
    end
  end

  describe 'compositor pattern' do
    let(:bulb_group_1) do
      described_class.new(name: :bulb_group_1, includes: [bulb_1])
    end

    let(:bulb_group_2) do
      described_class.new(name: :bulb_group_2, includes: [bulb_2])
    end

    let(:subject) do
      described_class.new(name: :name, includes: [bulb_group_1, bulb_group_2])
    end

    it 'moves forward a call to all the included bulbs' do
      expect(bulb_1).to receive(:call)
      expect(bulb_2).to receive(:call)

      subject.call
    end
  end

  describe 'iterator' do
    let(:bulb_group_1) do
      described_class.new(name: :bulb_group_1, includes: [bulb_1])
    end

    let(:bulb_group_2) do
      described_class.new(name: :bulb_group_2, includes: [bulb_2])
    end

    let(:subject) do
      described_class.new(name: :name, includes: [bulb_group_1, bulb_group_2])
    end

    it 'iterates correctly' do
      expect { |item| subject.each(&item) }
        .to yield_successive_args(bulb_1, bulb_2)
    end
  end

  describe '#add_items' do
    let(:bulb_3) { double(:bulb_3) }
    let(:bulb_4) { double(:bulb_4) }
    let(:bulb_5) { double(:bulb_5) }

    it 'adds new elements correctly' do
      expect { subject.add_items([bulb_3, bulb_4]) }
        .to change { subject.items }
        .from([bulb_1, bulb_2])
        .to([bulb_1, bulb_2, bulb_3, bulb_4])

      expect { subject << bulb_5 }
        .to change { subject.items }
        .from([bulb_1, bulb_2, bulb_3, bulb_4])
        .to([bulb_1, bulb_2, bulb_3, bulb_4, bulb_5])
    end
  end

  describe '#subgroups' do
    let(:bulb_group_1) do
      described_class.new(name: :bulb_group_1, includes: [bulb_1])
    end

    let(:bulb_group_2) do
      described_class.new(name: :bulb_group_2, includes: [bulb_2])
    end

    let(:bulb_3) { double(:bulb_3) }

    let(:subject) do
      described_class.new(
        name: :name,
        includes: [bulb_group_1, bulb_group_2, bulb_3]
      )
    end

    it 'returns subgroups' do
      expect(subject.subgroups).to contain_exactly(bulb_group_1, bulb_group_2)
    end
  end

  describe '#find_in_subgroups' do
    let(:bulb_group_1) do
      described_class.new(name: :bulb_group_1, includes: [bulb_1])
    end

    let(:bulb_group_2) do
      described_class.new(name: :bulb_group_2, includes: [bulb_2])
    end

    let(:bulb_3) { double(:bulb_3) }

    let(:subject) do
      described_class.new(
        name: :name,
        includes: [bulb_group_1, bulb_group_2, bulb_3]
      )
    end

    it 'returns subgroups' do
      expect(subject.find_in_subgroups(%i[bulb_group_1 bulb_group_2]))
        .to contain_exactly(bulb_group_1, bulb_group_2)
    end
  end

  describe '#find_lamps' do
    let(:bulb_group_1) do
      described_class.new(name: :bulb_group_1, includes: [bulb_1])
    end

    let(:bulb_group_2) do
      described_class.new(name: :bulb_group_2, includes: [bulb_2])
    end

    let(:bulb_3) { double(:bulb_3, name: :bulb_3, id: 3) }

    let(:subject) do
      described_class.new(
        name: :name,
        includes: [bulb_group_1, bulb_group_2, bulb_3]
      )
    end

    it 'returns lamps by id and name' do
      expect(subject.find_lamps([1, :bulb_3]))
        .to contain_exactly(bulb_1, bulb_3)
    end
  end

  describe '#subgroup' do
    let(:bulb_group_1) do
      described_class.new(name: :bulb_group_1, includes: [bulb_1])
    end

    let(:bulb_group_2) do
      described_class.new(name: :bulb_group_2, includes: [bulb_2])
    end

    let(:bulb_3) { double(:bulb_3, name: :bulb_3, id: 3) }

    let(:subject) do
      described_class.new(
        name: :name,
        includes: [bulb_group_1, bulb_group_2, bulb_3]
      )
    end

    it 'returns lamps by id and name' do
      expect(subject[:bulb_group_2]).to be bulb_group_2
    end
  end

  describe '#to_graph' do
    let(:bulb_group_1) do
      described_class.new(name: :bulb_group_1, includes: [bulb_1])
    end

    let(:bulb_group_2) do
      described_class.new(name: :bulb_group_2, includes: [bulb_2])
    end

    let(:bulb_3) do
      YeelightCli::Bulb.new(
        id: '1',
        Location: 'https://127.0.0.1',
        support: ['get_prop']
      )
    end

    let(:subject) do
      described_class.new(
        name: :name,
        includes: [bulb_group_1, bulb_group_2, bulb_3]
      )
    end

    before do
      allow(bulb_3).to receive(:load_props)
        .with(:power)
        .and_return(power: 'on')
    end

    it 'returns full graph' do
      expect(subject.to_graph)
        .to eq(
          "name\n  |\n  \e[m○\e[0m\n|\n|--bulb_group_1\n|\n|--bulb_group_2\n"
        )
    end

    it 'returns squashed graph' do
      expect(subject.to_graph(squash: true))
        .to eq("name\n  \e[m○\e[0m\n|--bulb_group_1\n|--bulb_group_2\n")
    end
  end
end
