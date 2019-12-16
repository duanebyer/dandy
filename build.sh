#!/usr/bin/bash
SOURCES="\
	main.vala test.vala \
	actor/air.vala \
		actor/item.vala actor/dandelion.vala actor/grass.vala actor/stalk.vala \
	draw/dandelion.vala draw/fluff.vala draw/grass.vala draw/leaf.vala \
		draw/stalk.vala draw/sky.vala \
	physics/air.vala physics/field.vala physics/vector_field.vala \
	util/camera.vala util/draw_util.vala util/fft.vala util/geometry.vala
		util/orbit.vala util/util.vala \
	"
valac $SOURCES -X -lm -X -fPIC -X -shared -o dandy.so \
	--library=Dandy --gir Dandy-0.1.gir \
	--pkg clutter-1.0 --pkg gee-0.8
g-ir-compiler --shared-library=dandy.so --output=Dandy-0.1.typelib Dandy-0.1.gir

