#!/usr/bin/bash
SOURCES="background.vala \
	util/orbit.vala util/util.vala util/draw_util.vala \
	draw/fluff.vala draw/stalk.vala draw/leaf.vala draw/grass.vala \
	draw/camera.vala"
valac $SOURCES -X -fPIC -X -shared -o dandy.so \
	--library=Dandy --gir Dandy-0.1.gir --pkg clutter-1.0
g-ir-compiler --shared-library=dandy.so --output=Dandy-0.1.typelib Dandy-0.1.gir

