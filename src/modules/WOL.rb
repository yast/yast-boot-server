# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2002 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
require "yast"

module Yast
  class WOLClass < Module
    def main
      textdomain "wol"
      Yast.import "Popup"

      @mac_addresses = []
      @modified = false
    end

    def Add(mac, host)
      @mac_addresses = Builtins.add(
        @mac_addresses,
        { "mac" => mac, "host" => host }
      )
      @modified = true
      true
    end

    def Change(old_mac, mac, host)
      new = []
      Builtins.foreach(
        Convert.convert(
          @mac_addresses,
          :from => "list <map>",
          :to   => "list <map <string, any>>"
        )
      ) do |row|
        if Ops.get_string(row, "mac", "") != old_mac
          new = Builtins.add(new, row)
        else
          new = Builtins.add(new, { "mac" => mac, "host" => host })
        end
      end
      @mac_addresses = deep_copy(new)
      true
    end

    def Read
      if Ops.greater_than(
          SCR.Read(path(".target.size"), "/var/lib/YaST2/wol"),
          0
        )
        wolfile = Convert.to_string(
          SCR.Read(path(".target.string"), "/var/lib/YaST2/wol")
        )
        pairs = Builtins.splitstring(wolfile, "\n")
        pairs = Builtins.filter(pairs) { |p| p != "" }
        @mac_addresses = Builtins.maplist(pairs) do |m|
          line = Builtins.splitstring(m, " ")
          { "mac" => Ops.get(line, 0, ""), "host" => Ops.get(line, 1, "") }
        end
      elsif Ops.greater_than(
          SCR.Read(path(".target.size"), "/etc/dhcpd.conf"),
          0
        )
        # read mac addr. from dhcpd.conf
        tmp = Ops.add(
          Convert.to_string(SCR.Read(path(".target.tmpdir"))),
          "/wol"
        )
        cmd = Builtins.sformat(
          "/usr/bin/wol-dhcpdconf < /etc/dhcpd.conf > %1",
          tmp
        )
        SCR.Execute(path(".target.bash"), cmd)
        wolfile = Convert.to_string(SCR.Read(path(".target.string"), tmp))
        pairs = Builtins.splitstring(wolfile, "\n")
        pairs = Builtins.filter(pairs) { |p| p != "" }
        @mac_addresses = Builtins.maplist(pairs) do |m|
          line = Builtins.splitstring(m, " ")
          { "mac" => Ops.get(line, 0, ""), "host" => Ops.get(line, 1, "") }
        end
        if Ops.greater_than(Builtins.size(@mac_addresses), 0)
          ret = Popup.YesNo(
            _(
              "No previously configured clients found.\n" +
                "However, a DHCP configuration was found on this system. Import the host\n" +
                "configuration data (MAC addresses and host names) from \n" +
                "'/etc/dhcpd.conf'?\n"
            )
          )
          if !ret
            @mac_addresses = []
          else
            @modified = true
          end
        end
      end
      true
    end

    def Write
      Builtins.y2debug("mac_addresses: %1", @mac_addresses)
      lines = Builtins.maplist(@mac_addresses) do |m|
        Ops.add(
          Ops.add(Ops.get_string(m, "mac", ""), " "),
          Ops.get_string(m, "host", "")
        )
      end
      wolfile = Builtins.mergestring(lines, "\n")
      SCR.Write(path(".target.string"), "/var/lib/YaST2/wol", wolfile)
      true
    end

    def Overview
      overview = Builtins.maplist(@mac_addresses) do |m|
        mac = Ops.get_string(m, "mac", "")
        host = Ops.get_string(m, "host", "")
        Item(Id(mac), mac, host)
      end
      deep_copy(overview)
    end

    publish :variable => :mac_addresses, :type => "list <map>"
    publish :variable => :modified, :type => "boolean"
    publish :function => :Add, :type => "boolean (string, string)"
    publish :function => :Change, :type => "boolean (string, string, string)"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Overview, :type => "list ()"
  end

  WOL = WOLClass.new
  WOL.main
end
