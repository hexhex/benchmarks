plugin_LTLIBRARIES = libdlvhexplugin-sensors.la

libdlvhexplugin_sensors_la_SOURCES = sensors.cpp

#
# extend compiler flags by CFLAGS of other needed libraries
#
AM_CPPFLAGS = \
	-I$(top_srcdir)/include \
	$(BOOST_CPPFLAGS) \
	$(DLVHEX_CFLAGS)

libdlvhexplugin_sensors_la_LDFLAGS = -avoid-version -module

