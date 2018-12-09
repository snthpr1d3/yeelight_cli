# frozen_string_literal: true

module YeelightCli
  # A bulb wrapper
  # rubocop:disable ClassLength
  class Bulb
    include Comparable

    BaseError = Class.new(RuntimeError)
    WrongDataFormatError = Class.new(BaseError)
    BlankIdError = Class.new(BaseError)
    BlankLocationError = Class.new(BaseError)
    UnsupportedActionError = Class.new(BaseError)
    ResponseError = Class.new(BaseError)

    attr_accessor :id, :uri, :specifications, :state, :logger
    attr_reader :name

    # rubocop:disable ParameterLists
    def initialize(
      data,
      socket_client: nil,
      color_processor: ColorProcessor,
      logger: initialize_default_logger,
      state_caching: true,
      args_validator: Bulb::ArgsValidator
    )
      @logger = logger
      @logger.debug "Initializing new object with data=#{data}"

      @args_validator = args_validator
      @args_validator.check_initial_data!(data)

      initialize_variables_from(data)

      @state_caching = state_caching
      fill_state_with(data) if state_caching?

      @socket_client = socket_client ||
                       TCPSocketClient.new(@uri.host, @uri.port)

      @color_processor = color_processor
    end
    # rubocop:enable ParameterLists

    def ==(other)
      return false unless other.is_a?(self.class)

      id == other.id
    end
    alias eql? ==

    def hash
      id.hash
    end

    def <=>(other)
      name <=> other.name
    end

    def to_s
      shutdown_timer = delayed_shutdown

      shutdown_string = if shutdown_timer
                          Paint[" shutdown_after=#{delayed_shutdown}", 'ff4444']
                        else
                          ''
                        end

      "<YeelightCli::Bulb id=#{id} name=#{name} "\
        "icon=#{to_icon}#{shutdown_string}>"
    end

    def get_prop(param)
      return @state[param] if state_caching? && @state[param]

      load_props(param)[param]
    end

    def set_prop(param, value)
      @state[param] = value if state_caching?
      value
    end

    def group_name(level = 1)
      return unless level.positive?

      chunks = name.split('/')
      return unless chunks.count > level

      chunks[level - 1]
    end

    def room
      group_name(1)
    end

    def to_icon
      Paint[brightness_character, current_color_in_rgb.to_s(16)]
    end

    def state_caching?
      @state_caching == true
    end

    # rubocop:disable MethodLength
    def brightness_character
      return 'x' if off?

      case brightness
      when 100
        '●'
      when 40..99
        '◕'
      when 10..39
        '◑'
      else
        '○'
      end
    end
    # rubocop:enable MethodLength

    def current_color_in_rgb
      return 0x888888 if off?

      case color_mode_name
      when :hsv
        @color_processor.huesat_to_rgb(hue, sat)
      when :temperature
        @color_processor.color_temperature_to_rgb(color_temperature)
      else
        rgb
      end
    end

    def support?(method)
      @specifications.include?(method.to_s) || method.to_s == 'set_name'
    end

    def on?
      get_prop(:power) == 'on'
    end

    def off?
      !on?
    end

    def toggle!
      perform :toggle

      return get_prop(:power) unless state_caching?

      new_power_state = on? ? 'off' : 'on'
      set_prop(:power, new_power_state)

      new_power_state
    end

    def name=(name)
      perform(:set_name, [name])
      @name = name
    end

    def set_brightness(brightness = 100, duration = 0)
      @args_validator.check_brightness!(brightness)
      @args_validator.check_duration!(duration)

      effect = duration.positive? ? :smooth : :sudden
      perform(:set_bright, [brightness, effect, duration])

      set_prop(:bright, brightness)
    end

    def brightness=(brightness = 100)
      @args_validator.check_brightness!(brightness)

      perform(:set_bright, [brightness, :sudden, 0])
      set_prop(:bright, brightness)
    end

    def brightness
      get_prop(:bright).to_i
    end

    def set_power(state = :on, duration = 0)
      @args_validator.check_duration!(duration)
      @args_validator.check_power_state!(state)

      effect = duration.positive? ? :smooth : :sudden
      perform(:set_power, [state, effect, duration])

      set_prop(:power, state.to_s)
    end

    def power=(state = :on)
      @args_validator.check_power_state!(state)

      perform(:set_power, [state, :sudden, 0])
      set_prop(:power, state.to_s)
    end

    def power
      get_prop(:power)
    end

    def color_mode
      get_prop(:color_mode).to_i
    end

    def color_mode_name
      return :rgb if rgb_color_mode?
      return :temperature if temperature_color_mode?
      return :hsv if hsv_color_mode?
    end

    def rgb_color_mode?
      color_mode == 1
    end

    def temperature_color_mode?
      color_mode == 2
    end

    def hsv_color_mode?
      color_mode == 3
    end

    def set_color_temperature(color_temperature = 6500, duration = 0)
      color_temperature = color_temperature.to_i

      @args_validator.check_color_temperature!(color_temperature)
      @args_validator.check_duration!(duration)

      effect = duration.positive? ? :smooth : :sudden
      perform(:set_ct_abx, [color_temperature, effect, duration])
      set_prop(:color_mode, 2)
      set_prop(:ct, color_temperature)
    end

    def color_temperature=(color_temperature = 6500)
      @args_validator.check_color_temperature!(color_temperature)

      perform(:set_ct_abx, [color_temperature, :sudden, 0])
      set_prop(:color_mode, 2)
      set_prop(:ct, color_temperature)
    end

    def color_temperature
      get_prop(:ct).to_i
    end

    def set_huesat(hue = 359, sat = 100, duration = 0)
      @args_validator.check_hue!(hue)
      @args_validator.check_sat!(sat)
      @args_validator.check_duration!(duration)

      effect = duration.positive? ? :smooth : :sudden
      perform(:set_hsv, [hue, sat, effect, duration])

      set_prop(:color_mode, 3)

      [set_prop(:hue, hue.to_i), set_prop(:sat, sat.to_i)]
    end

    def hue=(hue = 359)
      @args_validator.check_hue!(hue)

      sat = get_prop(:sat) || 100
      perform(:set_hsv, [hue, sat, :smooth, 0])
      set_prop(:color_mode, 3)
      set_prop(:hue, hue.to_i)
    end

    def sat=(sat = 100)
      @args_validator.check_sat!(sat)

      hue = get_prop(:hue) || 359
      perform(:set_hsv, [hue, sat, :smooth, 0])
      set_prop(:color_mode, 3)
      set_prop(:sat, sat.to_i)
    end

    def hue
      get_prop(:hue).to_i
    end

    def sat
      get_prop(:sat).to_i
      @state[:sat] ||= get_prop(:sat).to_i
    end

    def load_props(*params)
      props = perform(:get_prop, params)
      params.zip(props).to_h
    end

    # rubocop:disable RescueModifier
    def reload_state!
      return false unless state_caching?

      @logger.info 'Reloading state'

      actual_props = load_props(*@state.keys)

      actual_props.each do |prop_key, prop_value|
        casted_prop_value = Integer(prop_value) rescue nil
        value = casted_prop_value || prop_value

        @state[prop_key] = value if value.present?
      end

      @state
    end
    # rubocop:enable RescueModifier

    def set_rgb(rgb_value = 0xffffff, duration = 0)
      @args_validator.check_rgb!(rgb_value)
      @args_validator.check_duration!(rgb_value)

      effect = duration.positive? ? :smooth : :sudden
      perform(:set_rgb, [rgb_value, effect, duration])
      set_prop(:color_mode, 1)
      set_prop(:rgb, rgb_value)
    end

    def rgb=(rgb_value = 0xffffff)
      @args_validator.check_rgb!(rgb_value)

      perform(:set_rgb, [rgb_value, :smooth, 0])
      set_prop(:color_mode, 1)
      set_prop(:rgb, rgb_value)
    end

    def rgb
      get_prop(:rgb).to_i
    end

    def random_color!(duration = 0)
      random_color = Random.new.rand(0xffffff)
      set_rgb(random_color, duration)
    end

    def default!
      perform :set_default
    end

    def delayed_shutdown_after(minutes)
      @args_validator.check_timeout!(minutes)

      return cancel_delayed_shutdown! if minutes.zero?

      perform(:cron_add, [0, minutes])

      start_shutdown_thread_with(minutes * 60) if state_caching?

      minutes
    end
    alias delayed_shutdown= delayed_shutdown_after

    def delayed_shutdown
      perform(:cron_get, [0]).try(:first).try(:[], 'delay')
    end

    def cancel_delayed_shutdown!
      perform(:cron_del, [0])
      return true if !state_caching? || @shutdown_thread.blank?

      @shutdown_thread.kill
      @shutdown_thread = nil
      @logger.info 'The thread to update the power state has been killed'

      true
    end

    def adjust(action, prop)
      @args_validator.check_adjust_action!(action)
      @args_validator.check_adjust_prop!(prop)

      perform(:set_adjust, [action, prop])
      reload_state! if state_caching?

      [action, prop]
    end

    def adjust_brightness(percentage, duration = 0)
      @args_validator.check_percentage!(percentage)
      @args_validator.check_duration!(duration)

      perform(:adjust_bright, [percentage, duration])
      reload_state! if state_caching?

      off? ? 0 : brightness
    end

    def adjust_ct(percentage, duration = 0)
      @args_validator.check_percentage!(percentage)
      @args_validator.check_duration!(duration)

      perform(:adjust_ct, [percentage, duration])
      reload_state! if state_caching?

      color_temperature
    end

    def adjust_color(percentage, duration = 0)
      @args_validator.check_percentage!(percentage)
      @args_validator.check_duration!(duration)

      perform(:adjust_color, [percentage, duration])
      reload_state! if state_caching?

      rgb
    end

    def start_cf(count, action, expression)
      @args_validator.check_cf_count!(count)
      @args_validator.check_cf_action!(action)
      @args_validator.check_cf_expression!(expression)

      exp_array = expression.is_a?(Array) ? expression : expression.split(',')

      cancel_cf_thread! if state_caching?

      perform(:start_cf, [count, action, expression])

      start_cf_thread(count, exp_array) if state_caching? && count != 0

      true
    end

    def stop_cf
      perform :stop_cf

      return true unless state_caching?

      reload_state!
      cancel_cf_thread!

      true
    end

    def set_music(action, host, port)
      @args_validator.check_music_action!(action)
      @args_validator.check_host!(host)
      @args_validator.check_port!(port)

      action_code = action == :on ? 1 : 0
      perform(:set_music, [action_code, host, port])

      action == :on
    end

    def self.initialize_from_package(package_body)
      lines = package_body.lines
      _status_line = lines.shift

      data = lines
             .map { |line| line.strip.split(': ', 2) }
             .select { |processed_line| processed_line.count == 2 }
             .to_h
             .symbolize_keys

      new(data)
    end

    private

    def initialize_variables_from(data)
      @id = data.delete(:id).to_i(16)
      @uri = URI(data.delete(:Location))
      @model = data.delete(:model)
      @name = data.delete(:name)
      @specifications = data.delete(:support)
    end

    def fill_state_with(data)
      return false unless state_caching?

      new_state = {}

      @logger.debug "Filling state with data=#{data}"

      %i[bright color_mode ct rgb hue sat].each do |prop|
        new_state[prop] = data.delete(prop).to_i
      end

      # the state includes power, bright, color_mode, ct, rgb, hue, sat, name
      @state = data.merge(new_state)
      @logger.debug "The state now is #{@state}"

      @state
    end

    def perform(method, params = [])
      raise UnsupportedActionError unless support?(method)

      json = JSON.generate(id: 1, method: method, params: params) + "\r\n"
      @logger.debug "Socket request: #{json}"
      response = @socket_client.request(json)
      @logger.debug "Socket response: #{response}"

      result = response['result']
      raise ResponseError unless result

      result
    end

    def calculate_general_duration_from(count, exp_array)
      res = Array
            .new(count)
            .map.with_index { |_, i| exp_array[(i * 4) % exp_array.count].to_i }
            .sum

      @logger.debug "The calculated duraion for cf with count=#{count}, "\
        "exp_array=#{exp_array} is #{res}"

      res
    end

    def start_cf_thread(count, exp_array)
      return false unless state_caching?

      timeout = calculate_general_duration_from(count, exp_array).to_f / 1000

      @cf_thread = Thread.new do
        sleep timeout
        reload_state!
      end

      @logger.info 'The cf thread to actualize the state with '\
        "timeout=#{timeout} has been created"
    end

    def cancel_cf_thread!
      return false if !state_caching? || @cf_thread.blank?

      @cf_thread.kill
      @cf_thread = nil

      @logger.info 'The cf thread to actualize the state has been killed'
    end

    def start_shutdown_thread_with(timeout)
      return false unless state_caching?

      @shutdown_thread = Thread.new do
        sleep timeout
        @state[:power] = 'off'
        @logger.info 'The power state has been changed to "off"'
      end

      @logger.info 'A thread to update the power state with '\
        "timeout=#{timeout} has been created"

      timeout
    end

    def initialize_default_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::WARN
      logger
    end
  end
  # rubocop:enable ClassLength
end
