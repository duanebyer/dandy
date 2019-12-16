const Clutter = imports.gi.Clutter;
const Dandy = imports.gi.Dandy;

let width = 1028;
let height = 720;

Clutter.init(null);
let stage = new Clutter.Stage({
	width: width,
	height: height,
	background_color: new Clutter.Color({ red: 0, green: 0, blue: 0, alpha: 255 })
});
stage.connect("destroy", Clutter.main_quit);
/*
let dandy_actor = new Dandy.Test({
	width: width,
	height: height
});
*/
let dandy_actor = new Dandy.Main({
	width: width,
	height: height
});

stage.add_child(dandy_actor);
stage.show();

Clutter.main();

