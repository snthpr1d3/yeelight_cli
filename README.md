# YeelightCli

Remote control of yeelight bulbs in a local network.

**Bulbs need turning on remote control through a local network**

## First of all
  The bulbs have to be available to be controlled throught a local network using an open protocol. The easiest way to turn the remote control on is to use a mobile application such as "Yeelight" or "Mi Home".
  
  Here is going to be some screenshots.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yeelight_cli'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yeelight_cli

## Console client usage

**Synopsis:** `yeelight [global options] command [command options] [arguments...]`

You can get the full list of options and commands with `yeelight -h`

### Global options
Here is the list of global options you can use for any command:
* `-l lamp_identifier` perform a command only for a specific lamp using its identifier
* `-r room_name` perform a command only for a specific room
* `-g group_name` perform a command only for a specific group
* `-s subgroup_name` perform a command only for a specific subgroup
* `-d duration_in_ms` set a duration for command performing a light effect
* `-e` show a stack trace in case of error

### Commands
* `discover` prints names, ids and icons of all the selected lamps(lamps in the current network by default)
 screenshot
* `graph` shows the graph of all the selected lamps
and so on

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
