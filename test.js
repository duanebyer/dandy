imports.gi.versions.Gtk = '3.0';
const Cairo = imports.cairo;
const Clutter = imports.gi.Clutter;
const Gtk = imports.gi.Gtk;
const GtkClutter = imports.gi.GtkClutter;
const Lang = imports.lang;
const System = imports.system;

const Dandy = imports.gi.Dandy;

class Application {
	constructor() {
		this.application = new Gtk.Application();
		this.application.connect('activate', this._onActivate.bind(this));
		this.application.connect('startup', this._onStartup.bind(this));
	}

	_onStartup() {
		// Ideally the command line arguments should be given to Clutter here.
		// However, Clutter wants them by reference and I don't know how to do
		// that in GJS.
		GtkClutter.init(null);
		Clutter.init(null);

		this._window = new Gtk.ApplicationWindow({
			application: this.application,
			title: 'Hello world!',
			default_width: 800,
			default_height: 600
		});

		this.embed = new GtkClutter.Embed({
			width_request: 800,
			height_request: 600
		});

		/*
		this.dandy_actor = new Dandy.Test({
			width: 800,
			height: 600
		});
		*/
		this.dandy_actor = new Dandy.Simulation({
			width: 800,
			height: 600
		});

		let stage = this.embed.get_stage();
		stage.add_child(this.dandy_actor);

		this._window.add(this.embed);
	}

	_onActivate() {
		this._window.show_all();
	}
}

ARGV.unshift(System.programInvocationName);
let app = new Application();
app.application.run(ARGV);

