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
# File:	clients/wol.ycp
# Package:	Boot Server
# Author:      Anas Nashif <nashif@suse.de>
# Summary:	WOL
#

require "shellwords"

module Yast
  class WolClient < Client
    def main
      Yast.import "UI"

      textdomain "wol"
      Yast.import "Wizard"
      Yast.import "Label"
      Yast.import "WOL"
      Yast.import "Popup"
      Yast.import "Package"



      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("wol")
      Wizard.HideAbortButton
      if !Package.InstallAll(["wol"])
        Popup.Error(
          _(
            "Package could not be installed.\nInstall the missing packages and try again."
          )
        )
        return :auto
      end


      WOL.Read
      @overview = WOL.Overview

      #    term below_table = `PushButton(`id(`wake), _("Wake Up"));
      @contents =
        # Table header
        VBox(
          Table(Id(:table), Header(_("MAC Address"), _("Host Name")), @overview),
          VBox(
            PushButton(Id(:wake), _("Wake Up")),
            HBox(
              PushButton(Id(:add_button), Label.AddButton),
              PushButton(Id(:edit_button), Label.EditButton),
              PushButton(Id(:delete_button), Label.DeleteButton)
            )
          )
        )


      @caption = _("Wake-On-Lan")
      @help_text = _(
        "<h2>Wake on LAN</h2>\n" +
          "<p>With WOL, you can 'wake up' your PC simply by sending a 'magic packet' \n" +
          "over the network.</p>"
      )

      Wizard.SetContentsButtons(
        @caption,
        @contents,
        @help_text,
        Label.BackButton,
        Label.FinishButton
      )

      #    UI::ChangeWidget(`id(`edit_button), `Enabled, false);
      @ret = nil
      while true
        if Convert.to_string(UI.QueryWidget(Id(:table), :CurrentItem)) == nil
          UI.ChangeWidget(Id(:edit_button), :Enabled, false)
          UI.ChangeWidget(Id(:wake), :Enabled, false)
          UI.ChangeWidget(Id(:delete_button), :Enabled, false)
        else
          UI.ChangeWidget(Id(:edit_button), :Enabled, true)
          UI.ChangeWidget(Id(:wake), :Enabled, true)
          UI.ChangeWidget(Id(:delete_button), :Enabled, true)
        end

        @ret = UI.UserInput
        Builtins.y2debug("ret=%1", @ret)

        break if @ret == :cancel

        if @ret == :next
          WOL.Write
          break
        elsif @ret == :abort || @ret == :back
          if WOL.modified
            if Popup.ReallyAbort(true)
              break
            else
              next
            end
          else
            break
          end
        elsif @ret == :add_button
          AddorEdit(nil)
          @overview = WOL.Overview
          UI.ChangeWidget(Id(:table), :Items, @overview)
        elsif @ret == :delete_button
          if Popup.ContinueCancel(_("Really delete this item?"))
            @todelete = Convert.to_string(
              UI.QueryWidget(Id(:table), :CurrentItem)
            )
            WOL.mac_addresses = Builtins.filter(WOL.mac_addresses) do |m|
              Ops.get_string(m, "mac", "") != @todelete
            end
            @overview = WOL.Overview
            UI.ChangeWidget(Id(:table), :Items, @overview)
          end
        elsif @ret == :edit_button
          @toedit = Convert.to_string(UI.QueryWidget(Id(:table), :CurrentItem))
          AddorEdit(@toedit)
          @overview = WOL.Overview
          UI.ChangeWidget(Id(:table), :Items, @overview)
        elsif @ret == :wake
          mac = Convert.to_string(UI.QueryWidget(Id(:table), :CurrentItem))
          if mac != nil && mac != ""
            cmd = Builtins.sformat("/usr/bin/wol %1", mac.shellescape)
            Popup.ShowFeedback(_("Waking remote host"), mac)
            SCR.Execute(path(".target.bash"), cmd)
            Builtins.sleep(2000)
            Popup.ClearFeedback
          end
        end
      end

      Wizard.CloseDialog
      Convert.to_symbol(@ret)
    end

    def AddorEdit(to_edit)
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          HCenter(
            HSquash(
              VBox(
                HCenter(
                  HSquash(
                    VBox(
                      Left(VSpacing(0.2)),
                      VSpacing(0.2),
                      Left(TextEntry(Id(:host), _("Host Name:"))),
                      Left(
                        TextEntry(Id(:mac), _("MAC Address of\nthe Client: "))
                      )
                    )
                  )
                ),
                HSquash(
                  HBox(
                    PushButton(Id(:save), Label.SaveButton),
                    PushButton(Id(:cancel), Label.CancelButton)
                  )
                ),
                VSpacing(0.2)
              )
            )
          ),
          HSpacing(1)
        )
      )
      if to_edit != nil
        Builtins.foreach(
          Convert.convert(
            WOL.mac_addresses,
            :from => "list <map>",
            :to   => "list <map <string, string>>"
          )
        ) do |row|
          if to_edit == Ops.get(row, "mac", "")
            UI.ChangeWidget(:host, :Value, Ops.get(row, "host", ""))
            UI.ChangeWidget(:mac, :Value, to_edit)
          end
        end
      end

      ret = nil
      while true
        ret = Wizard.UserInput
        Builtins.y2debug("ret=%1", ret)
        if ret == :save
          mac = Convert.to_string(UI.QueryWidget(Id(:mac), :Value))
          host = Convert.to_string(UI.QueryWidget(Id(:host), :Value))
          if to_edit == nil
            WOL.Add(mac, host)
          else
            WOL.Change(to_edit, mac, host)
          end
          break
        elsif ret == :back
          break
        end
      end
      UI.CloseDialog
      Convert.to_symbol(ret)
    end
  end
end

Yast::WolClient.new.main
