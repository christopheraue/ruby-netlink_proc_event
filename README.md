# NetlinkProcEvent

Bindings for netlink to handle process events like fork, exec, etc.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'netlink_proc_events'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install netlink_proc_events

## Usage

```ruby
require 'netlink_proc_event'

NetlinkProcEvent.on :PROC_EVENT_FORK do |event|
  puts "#{event[:parent_pid]} forked into #{event[:child_pid]}"
end

NetlinkProcEvent.on :PROC_EVENT_EXEC do |event|
  puts "#{event[:process_pid]} exec'd"
end

NetlinkProcEvent.on :PROC_EVENT_EXIT do |event|
  puts "#{event[:process_pid]} killed"
end

loop do
  Kernel.select([NetlinkProcEvent.socket]).each do |socket|
    NetlinkProcEvent.handle_events
  end
end
```
