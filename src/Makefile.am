# Sources for boot-server

module_DATA = \
  modules/WOL.rb

client_DATA = \
  clients/wol.rb

desktop_DATA = \
  desktop/org.opensuse.yast.WoL.desktop

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-wol-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-wol.svg

EXTRA_DIST = $(module_DATA) $(client_DATA) $(desktop_DATA) $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
