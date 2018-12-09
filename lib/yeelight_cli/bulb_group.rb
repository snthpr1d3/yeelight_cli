module YeelightCli
  # Bulbs container
  class BulbGroup
    include Enumerable
    include Comparable

    attr_accessor :name, :items

    def initialize(name:, includes: [])
      @name = name
      @items = []

      self << includes
    end

    def ==(other)
      name == other.name && items == other.items
    end

    def <=>(other)
      name <=> other.name
    end

    def each(&block)
      @items.each do |item|
        next item.each(&block) if item.is_a?(self.class)

        yield item
      end
    end

    def respond_to_missing?(method_name, include_priv)
      YeelightCli::Bulb.instance_methods.include?(method_name) || super
    end

    # rubocop:disable MethodMissingSuper
    def method_missing(method_name, *args, &block)
      @items.map do |item|
        item.send(method_name, *args, &block)
      end.flatten
    end
    # rubocop:enable MethodMissingSuper

    def add_items(elements)
      @items += Array.wrap(elements)
    end
    alias << add_items

    def subgroups
      @items.select { |item| item.class == self.class }
    end

    def find_in_subgroups(names)
      casted_names = names.map(&:to_s)
      subgroups.select { |item| item.name.to_s.in?(casted_names) }
    end

    def find_lamps(identifiers)
      casted_identifiers = Array.wrap(identifiers).map(&:to_s)

      select do |item|
        item.name.to_s.in?(casted_identifiers) ||
          item.id.to_s.in?(casted_identifiers)
      end
    end

    def subgroup(name)
      @items.find { |item| item.name.to_s == name.to_s }
    end
    alias [] subgroup

    def subgroup_names
      @items.map(&:name)
    end

    def to_icons
      map(&:to_icon).join
    end

    def to_graph(bulb_group: self, deep_level: 0, squash: false)
      graph = draw_bulb_group(bulb_group, squash, deep_level)

      bulb_group.items.group_by(&:class).tap do |grouped_items|
        child_groups = grouped_items[self.class].try(:sort)
        child_bulbs = grouped_items[Bulb].try(:sort)

        graph << draw_bulbs(child_bulbs, deep_level, squash) if child_bulbs

        if child_groups
          graph << draw_bulb_groups(child_groups, squash, deep_level + 1)
        end
      end

      graph
    end

    private

    def draw_bulb_groups(bulb_groups, squash, deep_level)
      bulb_groups.map do |bulb_group|
        to_graph(
          bulb_group: bulb_group,
          deep_level: deep_level,
          squash: squash
        )
      end.join
    end

    # rubocop:disable AbcSize
    def draw_bulb_group(bulb_group, squash, deep_level = 0)
      result = ''

      if deep_level.positive?
        result << '    ' * (deep_level - 1) + '|' + "\n" unless squash
        result << '    ' * (deep_level - 1) + '|' + '--'
      end

      result + bulb_group.name.to_s + "\n"
    end
    # rubocop:enable AbcSize

    def draw_bulbs(bulbs, deep_level, squash)
      bulb_icons = bulbs.map(&:to_icon)
      result = ''
      result = '   ' * deep_level + '  ' + '|' + "\n" unless squash
      result + '   ' * deep_level + '  ' + bulb_icons.join + "\n"
    end
  end
end
