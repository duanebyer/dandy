namespace Dandy {

public class Simulation : Clutter.Actor {
	private Gee.ArrayList<ItemActor> _items;
	private Camera _camera;
	private TimeoutSource _timer;

	private class ItemActor {
		public Item.Item item;
		public Clutter.Actor actor;
	}

	public Simulation() {
		Object();
	}

	construct {
		// Create the camera.
		this._camera = this.construct_camera();

		// Generate the items and create an actor to represent each item.
		this._items = new Gee.ArrayList<ItemActor>();
		foreach (Item.Item item in this.construct_items()) {
			// Create the actor.
			Clutter.Actor actor = new Clutter.Actor();
			actor.set_background_color(Clutter.Color.from_string("#ff0000"));
			actor.set_content(item.canvas);
			actor.set_size(
				(float) item.bounds.width(),
				(float) item.bounds.height());
			actor.set_pivot_point(
				(float) (-item.bounds.p1.x / item.bounds.width()),
				(float) (-item.bounds.p1.y / item.bounds.height()));
			this.add_child(actor);

			ItemActor item_actor = new ItemActor() {
				item = item,
				actor = actor
			};
			this.update_item_actor(item_actor);
			this._items.add(item_actor);
		}

		// Connect signals.
		this.allocation_changed.connect((e) => {
			this.on_resize(e.get_width(), e.get_height());
		});

		this._timer = new TimeoutSource(30);
		this._timer.set_callback(() => {
			this.on_step();
			return Source.CONTINUE;
		});
		this._timer.attach(null);
	}

	private Camera construct_camera() {
		double viewport_width = this.get_width();
		double viewport_height = this.get_height();
		return Camera() {
			pos = Util.Vector3(0, 0, -0.5 * viewport_width),
			tilt = 0,
			fov = 60 * Math.PI / 180,
			viewport = Util.Bounds(0, 0, viewport_width, viewport_height),
			reference_distance = viewport_width
		};
	}

	private Gee.ArrayList<Item.Item> construct_items() {
		Gee.ArrayList<Item.Item> items = new Gee.ArrayList<Item.Item>();
		for (uint idx = 0; idx < 1; ++idx) {
			Item.Item next = new Item.Stalk();
			next.pos = Util.Vector3(
				this.get_width() * Random.next_double(),
				0.5 * this.get_height(),
				this.get_width() * Random.next_double());
			items.add(next);
		}
		return items;
	}

	private void update_item_actor(ItemActor item_actor) {
		Item.Item item = item_actor.item;
		Clutter.Actor actor = item_actor.actor;

		// Find the parameters describing how the item should appear.
		Util.Vector3 screen_pos = this._camera.transform(item.pos);
		double angle = item.angle;
		double scale_x = this._camera.scale_x(item.pos);
		double scale_y = scale_x;
		if (item.billboard_mode == Item.Item.BillboardMode.FACING_CAMERA) {
			scale_y = scale_x;
		} else if (item.billboard_mode == Item.Item.BillboardMode.UPRIGHT) {
			scale_y = this._camera.scale_y(item.pos);
		}

		// Update the position and scale of the actor.
		actor.set_position(
			(float) (screen_pos.x + item.bounds.p1.x),
			(float) (screen_pos.y + item.bounds.p1.y));
		actor.set_z_position((float) screen_pos.z);
		actor.set_rotation_angle(
			Clutter.RotateAxis.Z_AXIS,
			Math.PI / 180 * angle);
		//actor.set_scale(scale_x, scale_y);
	}

	private void on_resize(float new_width, float new_height) {
		this._camera = this.construct_camera();
		foreach (ItemActor item_actor in this._items) {
			this.update_item_actor(item_actor);
		}
	}

	private void on_step() {
	}
}

}

