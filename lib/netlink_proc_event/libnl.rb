#
# Copyright (c) 2015, Christopher Aue <mail@christopheraue.net>
#
# This file is part of the ruby netlink_proc_event gem. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this distribution and at
# http://github.com/christopheraue/netlink_proc_event.
#

# derived from https://github.com/cultureulterior/ruby-netlink-libnl3/blob/master/libnl3.rb

require 'ffi'
require 'ffi/tools/const_generator'

module NetlinkProcEvent
  module Libnl
    extend FFI::Library
    ffi_lib 'libnl-3.so'

    %w(CN_IDX_PROC CN_VAL_PROC NETLINK_CONNECTOR NLMSG_DONE).each do |const|
      const_set(const,
        FFI::ConstGenerator.new(nil, :required => true) do |gen|
          gen.include 'linux/connector.h'
          gen.include 'linux/netlink.h'
          gen.const(const)
        end[const].to_i
      )
    end

    Event = enum(
      :PROC_EVENT_NONE , 0x00000000,
      :PROC_EVENT_FORK , 0x00000001,
      :PROC_EVENT_EXEC , 0x00000002,
      :PROC_EVENT_UID  , 0x00000004,
      :PROC_EVENT_GID  , 0x00000040,
      :PROC_EVENT_SID  , 0x00000080,
      :PROC_EVENT_PTRACE , 0x00000100,
      :PROC_EVENT_COMM , 0x00000200,
      :PROC_EVENT_EXIT , -0x80000000)

    class ForkProcEvent < FFI::Struct
      layout :parent_pid, :pid_t,
        :parent_tgid, :pid_t,
        :child_pid, :pid_t,
        :child_tgid, :pid_t
    end

    class ExecProcEvent < FFI::Struct
      layout :process_pid, :pid_t,
        :process_tgid, :pid_t
    end

    class ExitProcEvent < FFI::Struct
      layout :process_pid, :pid_t,
        :process_tgid, :pid_t,
        :exit_signal, :uint32
    end

    class EventData < FFI::Union
      layout :fork, ForkProcEvent,
        :exec, ExecProcEvent,
        :exit, ExitProcEvent
    end

    class ProcEvent < FFI::Struct
      layout :idx, :uint32,
        :val, :uint32,
        :seq, :uint32,
        :ack, :uint32,
        :len, :uint16,
        :flags, :uint16,
        :what, Event,
        :cpu, :uint32,
        :timestamp_ns, :uint32,
        :timestamp_ns, :uint32,
        :event_data, EventData
    end

    class CnMsg < FFI::Struct
      layout :idx, :uint32,
        :val, :uint32,
        :seq, :uint32,
        :ack, :uint32,
        :len, :uint16,
        :flags, :uint16,
        :data, :uint32
    end

    attach_function :nl_socket_alloc, [], :pointer
    attach_function :nl_socket_get_fd, [:pointer], :int
    attach_function :nl_connect, [:pointer,:int], :int
    attach_function :nlmsg_data, [:pointer], :pointer
    attach_function :nl_send_auto, [:pointer,:pointer], :int
    attach_function :nl_geterror, [:int], :string
    attach_function :nl_socket_disable_seq_check, [:pointer], :void
    attach_function :nlmsg_alloc_simple, [:int, :int], :pointer
    attach_function :nlmsg_reserve, [:pointer, :size_t, :int], :pointer
    attach_function :nl_socket_disable_auto_ack, [:pointer], :void
    attach_function :nl_join_groups, [:pointer, :int], :void
    attach_function :nl_socket_enable_msg_peek, [:pointer], :void
    attach_function :nl_recv, [:pointer, :pointer, :pointer, :pointer], :int
    attach_function :nlmsg_ok, [:pointer, :int], :int

    def self.log(logger, what, error, abovezero = nil)
      return unless logger
      if abovezero && error >= 0
        logger.debug "#{what}: #{abovezero} (#{error})"
      else
        logger.debug "#{what}: #{nl_geterror(error)} (#{error})"
      end
    end
  end
end