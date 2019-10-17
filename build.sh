#!/usr/bin/bash
SOURCES="\
	simulation.vala test.vala camera.vala \
	util/draw_util.vala util/geometry.vala util/orbit.vala util/util.vala \
	draw/fluff.vala draw/grass.vala draw/leaf.vala draw/stalk.vala \
	item/item.vala item/stalk.vala item/grass.vala \
	"
valac $SOURCES -X -fPIC -X -shared -o dandy.so \
	--library=Dandy --gir Dandy-0.1.gir \
	--pkg clutter-1.0 --pkg gee-0.8
g-ir-compiler --shared-library=dandy.so --output=Dandy-0.1.typelib Dandy-0.1.gir

