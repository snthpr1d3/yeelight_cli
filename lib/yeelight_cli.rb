require 'socket'
require 'json'
require 'timeout'
require 'ipaddr'
require 'optparse'
require 'logger'
require 'paint'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/inclusion'
require 'active_support/core_ext/array/wrap'

# The entry point of the gem
module YeelightCli
  MULTICAST_ADDRESS = '239.255.255.250'.freeze
  MULTICAST_PORT = 1982
  DISCOVER_TIMEOUT_SEC = 0.2
  SOCKET_RESPONSE_MAX_LENGTH = 2048

  # rubocop:disable IndentHeredoc
  DISCOVER_PAYLOAD = <<-PAYLOAD.freeze
M-SEARCH * HTTP/1.1\r
HOST: #{MULTICAST_ADDRESS}:#{MULTICAST_PORT}\r
MAN: "ssdp:discover"\r
ST: wifi_bulb
  PAYLOAD
  # rubocop:enable IndentHeredoc

  class << self
    def discover(
      socket: UDPSocket.new(Socket::AF_INET),
      multicast_address: MULTICAST_ADDRESS,
      multicast_port: MULTICAST_PORT,
      discover_timeout_sec: DISCOVER_TIMEOUT_SEC,
      socket_response_max_length: SOCKET_RESPONSE_MAX_LENGTH
    )
      socket.send(DISCOVER_PAYLOAD, 0, multicast_address, multicast_port)

      packages = collect_packages(
        discover_timeout_sec,
        socket,
        socket_response_max_length
      )

      bulb_set = packages.map(&Bulb.method(:initialize_from_package)).to_set
      splitted_bulbs = split_bulbs_by_group_names(bulb_set)
      turn_into_composite_structure(splitted_bulbs)
    end

    def discover!(
      socket: UDPSocket.new(Socket::AF_INET),
      multicast_address: MULTICAST_ADDRESS,
      multicast_port: MULTICAST_PORT,
      discover_timeout_sec: DISCOVER_TIMEOUT_SEC,
      socket_response_max_length: SOCKET_RESPONSE_MAX_LENGTH
    )
      heap = discover(
        socket: socket,
        multicast_address: multicast_address,
        multicast_port: multicast_port,
        discover_timeout_sec: discover_timeout_sec,
        socket_response_max_length: socket_response_max_length
      )

      raise 'No bulbs have been found' if heap.none?

      heap
    end

    private

    def collect_packages(discover_timeout_sec, socket, response_max_length)
      packages = []

      begin
        Timeout.timeout(discover_timeout_sec) do
          loop { packages << socket.recvfrom(response_max_length).first }
        end
      rescue Timeout::Error
        nil
      end

      packages
    end

    def split_bulbs_by_group_names(bulb_set, current_level = 1)
      grouped_bulbs = bulb_set.group_by do |bulb|
        bulb.group_name(current_level)
      end

      grouped_bulbs.map do |group_name, bulbs|
        next [group_name, bulbs] if group_name.nil?

        content = bulbs.group_by { |bulb| bulb.group_name(current_level + 1) }
        [group_name, content]
      end.to_h
    end

    def turn_into_composite_structure(splitted_bulbs, split_name = 'main')
      current_group = BulbGroup.new(name: split_name)

      splitted_bulbs.each do |group_name, bulbs|
        if !group_name.nil? && bulbs.is_a?(Hash)
          next current_group << turn_into_composite_structure(bulbs, group_name)
        end

        next current_group << bulbs if group_name.nil?

        current_group << BulbGroup.new(name: group_name, includes: bulbs)
      end

      current_group
    end
  end
end
