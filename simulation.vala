namespace Dandy {

public class Simulation : Clutter.Actor {
	private Gee.ArrayList<ItemActor> _items;
	private Camera _camera;
	private TimeoutSource _timer;
	private bool _scene_exists;

	private class ItemActor {
		public Item.Item item;
		public Clutter.Actor actor;
	}

	public Simulation() {
		Object();
	}

	construct {
		// Try to make the scene.
		this.create_scene(this.get_width(), this.get_height());

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

	private Camera create_camera(double width, double height) {
		double viewport_width = width;
		double viewport_height = height;
		return new Camera(
			Util.Vector3(0, 0, -0.5 * viewport_width),
			0,
			60 * Math.PI / 180,
			-0.25 * viewport_width, 1.25 * viewport_width,
			Util.Bounds(0, 0, viewport_width, viewport_height));
	}

	private Gee.ArrayList<Item.Item> create_items(double width, double height) {
		Gee.ArrayList<Item.Item> items = new Gee.ArrayList<Item.Item>();
		for (uint idx = 0; idx < 10; ++idx) {
			Item.Item next = new Item.Stalk();
			next.pos = Util.Vector3(
				Random.double_range(-0.5 * width, 0.5 * width),
				-0.25 * height,
				Random.double_range(0, width));
			items.add(next);
		}
		return items;
	}

	private void create_scene(double width, double height) {
		// Don't bother trying if the new width and height are too small.
		if (width <= 0 || height <= 0) {
			this._scene_exists = false;
			return;
		}

		this._scene_exists = true;

		// Create the camera.
		this._camera = this.create_camera(width, height);

		// Generate the items and create an actor to represent each item.
		this._items = new Gee.ArrayList<ItemActor>();
		foreach (Item.Item item in this.create_items(width, height)) {
			// Create the actor.
			Clutter.Actor actor = new Clutter.Actor();
			actor.set_content(item.canvas);
			actor.set_size(
				(float) item.bounds.width(),
				(float) item.bounds.height());
			actor.set_pivot_point(
				(float) (-item.bounds.p1.x / item.bounds.width()),
				(float) (-item.bounds.p1.y / item.bounds.height()));

			ItemActor item_actor = new ItemActor() {
				item = item,
				actor = actor
			};
			this.update_item_actor(item_actor);
			this._items.add(item_actor);
			this.add_child(actor);
		}

		// Do an insertion sort to make sure the actors are sorted correctly.
		uint child_count = this.get_children().length();
		for (int idx = 1; idx < (int) child_count; ++idx) {
			for (int compare_idx = idx - 1; compare_idx >= 0; --compare_idx) {
				Clutter.Actor next_child = this.get_child_at_index(compare_idx + 1);
				Clutter.Actor prev_child = this.get_child_at_index(compare_idx);
				if (next_child.z_position > prev_child.z_position) {
					break;
				} else {
					this.set_child_below_sibling(next_child, prev_child);
				}
			}
		}

		this._scene_exists = true;
	}

	private void update_item_actor(ItemActor item_actor) {
		if (!this._scene_exists) {
			return;
		}
		Item.Item item = item_actor.item;
		Clutter.Actor actor = item_actor.actor;

		// Find the parameters describing how the item should appear.
		Util.Vector3 screen_pos = this._camera.transform(item.pos);
		double angle = item.angle;
		double scale_x = this._camera.transform_vector(
			item.pos,
			Util.Vector3.UNIT_X).x;
		double scale_y = scale_x;
		if (item.billboard_mode == Item.Item.BillboardMode.FACING_CAMERA) {
			scale_y = scale_x;
		} else if (item.billboard_mode == Item.Item.BillboardMode.UPRIGHT) {
			scale_y = this._camera.transform_vector(
				item.pos,
				Util.Vector3.UNIT_Y).y;
		}

		// Update the position and scale of the actor.
		actor.set_position(
			(float) (screen_pos.x + item.bounds.p1.x),
			(float) (screen_pos.y + item.bounds.p1.y));
		actor.set_z_position(1 - (float) screen_pos.z);
		actor.set_rotation_angle(
			Clutter.RotateAxis.Z_AXIS,
			Math.PI / 180 * angle);
		actor.set_scale(scale_x, scale_y);
	}

	// On a resize, we have to basically recreate the entire scene.
	private void on_resize(float new_width, float new_height) {
		this.create_scene((double) new_width, (double) new_height);
	}

	private void on_step() {
	}
}

}

