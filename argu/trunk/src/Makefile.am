#
# replace 'plugin' on the right side by your plugin's name
#
plugin_LTLIBRARIES = libdlvhexplugin-string.la

#
# replace 'plugin' on the left side as above and
# add all sources of your plugin
#
libdlvhexplugin_string_la_SOURCES = stringplugin.cpp

#
# extend compiler flags by CFLAGS of other needed libraries
#
AM_CPPFLAGS = \
	-I$(top_srcdir)/include \
	$(BOOST_CPPFLAGS) \
	$(DLVHEX_CFLAGS)

libdlvhexplugin_string_la_LDFLAGS = -avoid-version -module


libdlvhexplugin-string-static.la: $(libdlvhexplugin_string_la_OBJECTS)
	$(CXXLINK) -avoid-version -module -rpath $(plugindir) $(libdlvhexplugin_string_la_OBJECTS)

install-static: libdlvhexplugin-string-static.la
	$(LIBTOOL) --mode=install $(INSTALL) -s libdlvhexplugin-string-static.la $(DESTDIR)$(plugindir)/libdlvhexplugin-string-static.la

uninstall-static:
	$(LIBTOOL) --mode=uninstall rm -f $(DESTDIR)$(plugindir)/libdlvhexplugin-string-static.la
