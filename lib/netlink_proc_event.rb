#
# Copyright (c) 2015, Christopher Aue <mail@christopheraue.net>
#
# This file is part of the ruby netlink_proc_event gem. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this distribution and at
# http://github.com/christopheraue/netlink_proc_event.
#

require 'netlink_proc_event/version'
require 'netlink_proc_event/libnl'
require 'socket'

module NetlinkProcEvent
  class << self
    attr_accessor :logger

    def socket
      UNIXSocket.for_fd(Libnl.nl_socket_get_fd(nl_socket))
    end

    def handle_events
      nl_sockaddr = FFI::MemoryPointer.new(32)
      ptr_to_msg_ptr = FFI::MemoryPointer.new(:pointer)

      msg_length = Libnl.nl_recv(nl_socket, nl_sockaddr, ptr_to_msg_ptr, nil)
      msg_ptr = ptr_to_msg_ptr.read_pointer
      msg_valid = Libnl.nlmsg_ok(msg_ptr, msg_length) > 0

      if msg_length > 0 && msg_ptr && msg_valid
        msg_payload_ptr = Libnl.nlmsg_data(msg_ptr)
        msg_payload = Libnl::ProcEvent.new(msg_payload_ptr)
        handle_event(msg_payload)
      end
    end

    def on(event, &handler)
      check_event(event)
      subscribe_to_proc_events
      event_handlers[event] ||= []
      event_handlers[event] << handler
      handler
    end

    def off(event, handler)
      check_event(event)
      return unless event_handlers[event]
      event_handlers[event].delete(handler)
      event_handlers.delete(event) if event_handlers[event].empty?
    end

    private

    def nl_socket
      @nl_socket ||= Libnl.nl_socket_alloc.tap do |socket|
        Libnl.nl_socket_disable_seq_check(socket)
        Libnl.nl_join_groups(socket, Libnl::CN_IDX_PROC)
        Libnl.log(@logger, "Netlink connection attempt", Libnl.nl_connect(socket, Libnl::NETLINK_CONNECTOR))
        Libnl.nl_socket_disable_auto_ack(socket)
        Libnl.nl_socket_disable_seq_check(socket)
        Libnl.nl_socket_enable_msg_peek(socket)
      end
    end

    def event_handlers
      @event_handlers ||= {}
    end

    def check_event(event)
      Libnl::Event[event] || raise("Unknown event #{event}.")
    end

    def subscribe_to_proc_events
      return if @subscribed_to_proc_events

      msg = Libnl.nlmsg_alloc_simple(Libnl::NLMSG_DONE, 0)
      data = Libnl.nlmsg_reserve(msg, 24, 4)

      proc_message = Libnl::CnMsg.new(data)
      proc_message[:idx] = Libnl::CN_IDX_PROC
      proc_message[:val] = Libnl::CN_VAL_PROC
      proc_message[:data] = 1
      proc_message[:len] = 4 # Contains an int
      proc_message[:seq] = 0
      proc_message[:ack] = 0

      Libnl.log(@logger, "Netlink subscribed to proc events", Libnl.nl_send_auto(nl_socket, msg), 'Success')

      @subscribed_to_proc_events = true
    end

    def handle_event(event)
      if event_handlers[event[:what]]
        type = event[:what].to_s.split('_').last.downcase.to_sym
        event_handlers[event[:what]].each{ |handler| handler.call(event[:event_data][type]) }
        true
      else
        false
      end
    end
  end
end
