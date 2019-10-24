namespace Dandy {

public class Simulation : Clutter.Actor {
	private Gee.ArrayList<ItemActor> _items;
	private Clutter.Actor _background;
	private Clutter.Actor _item_parent;
	private Camera _camera;
	private TimeoutSource _timer;
	private bool _scene_exists;

	private Util.Bounds3 _scene_bounds;
	private double _hill_curvature;
	private Util.Vector3 _hill_vertex;

	private double hill_height(double x, double z) {
		return this._hill_vertex.y + this._hill_curvature * (
			Util.square((this._hill_vertex.x - x) / this._scene_bounds.width())
			+ Util.square((this._hill_vertex.z - z) / this._scene_bounds.depth()));
	}

	private Item.Item.Effects defocus_effect(double z) {
		double defocus =
			0.5 * (z - this._scene_bounds.center().z)
			/ this._scene_bounds.depth();
		double blur_radius = 14 * Math.fabs(defocus);
		double tint = 0;
		return Item.Item.Effects() {
			blur_radius = blur_radius,
			tint = tint
		};
	}

	private class ItemActor {
		public Item.Item item;
		public Clutter.Actor actor;
		public Util.Vector3 screen_pos;
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

	private void create_camera(double width, double height) {
		double viewport_width = width;
		double viewport_height = height;
		Util.Vector3 pos = this._scene_bounds.center();
		double near = 0.15 * this._scene_bounds.depth();
		double far = near + this._scene_bounds.depth();
		pos.z = this._scene_bounds.p1.z - near;
		pos.y += 0.5 * this._scene_bounds.height();
		this._camera = new Camera(
			pos,
			10 * Math.PI / 180,
			60 * Math.PI / 180,
			near, far,
			Util.Bounds(0, 0, viewport_width, viewport_height));
	}

	private void create_background(double width, double height) {
		int pix_width = (int) Math.ceil(width);
		int pix_height = (int) Math.ceil(height);
		Clutter.Canvas canvas = new Clutter.Canvas() {
			width = pix_width,
			height = pix_height
		};
		Draw.SkyParams sky_params = Draw.SkyParams.generate(pix_width, pix_height);
		Draw.SkyDetails sky_details = Draw.SkyDetails.generate(sky_params);
		Cairo.ImageSurface image = new Cairo.ImageSurface(
			Cairo.Format.ARGB32,
			pix_width,
			pix_height);
		Cairo.Context image_ctx = new Cairo.Context(image);
		image_ctx.save();
		Draw.draw_sky(image_ctx, sky_params, sky_details);
		image_ctx.restore();
		image.flush();

		DrawUtil.blur_image_box(image, 2);

		canvas.draw.connect((canvas, ctx, w, h) => {
			ctx.save();
			ctx.set_source_surface(image, 0, 0);
			ctx.set_operator(Cairo.Operator.SOURCE);
			ctx.paint();
			ctx.restore();
			return false;
		});
		canvas.invalidate();
		this._background.set_content(canvas);
	}

	private void create_hill() {
		this._hill_curvature = 0;
		this._hill_curvature = Random.next_double() > 0.25 ?
			Random.double_range(30, 60) :
			Random.double_range(-17, -13);
		this._hill_vertex = Util.Vector3(
			Random.double_range(this._scene_bounds.p1.x, this._scene_bounds.p2.x),
			this._scene_bounds.center().y,
			Random.double_range(this._scene_bounds.p1.z, this._scene_bounds.p2.z));
	}

	private void create_item_actors() {
		this._items = new Gee.ArrayList<ItemActor>();
		foreach (Item.Item item in this.generate_items()) {
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
				actor = actor,
				// The screen position must be set to the negative maximum to
				// start with, to ensure that it is behind every other item.
				screen_pos = Util.Vector3(0, 0, double.INFINITY)
			};
			this._item_parent.add_child(actor);
			this._item_parent.set_child_above_sibling(actor, null);
			// But at the top of the item list (sorted by depth).
			this._items.add(item_actor);
			this.update_item_actor(this._items.size - 1);
		}
	}

	private Gee.ArrayList<Item.Item> generate_items() {
		Gee.ArrayList<Item.Item> items = new Gee.ArrayList<Item.Item>();
		// Generate the grass.
		double grass_x_rel = 0;
		double grass_z_rel = 0;
		// TODO: Make this into two separate loops, so that z-related variables
		// don't have to be recalculated every pass.
		while (grass_z_rel < 1) {
			double grass_x_step = 1.0 / 10;
			double grass_z_step = 1.0 / 10;
			double grass_z = Util.lerp(
				this._scene_bounds.p1.z,
				this._scene_bounds.p2.z,
				grass_z_rel);
			Util.Bounds bounds_at_z = this._camera.bounds_at_z(grass_z);
			double grass_x = Util.lerp(
				bounds_at_z.p1.x,
				bounds_at_z.p2.x,
				grass_x_rel);
			double grass_y = this.hill_height(grass_x, grass_z);
			Util.Vector3 grass_pos = Util.Vector3(grass_x, grass_y, grass_z);
			double z_scale =
				(this._camera.transform_vector(grass_pos, Util.Vector3.UNIT_Z).y
				/ this._camera.transform_vector(grass_pos, Util.Vector3.UNIT_X).x).abs();
			double grass_width = grass_x_step * bounds_at_z.width();
			double grass_height = grass_z_step * this._scene_bounds.depth() * z_scale;
			double grass_scale =
				this._camera.transform_vector(grass_pos, Util.Vector3.UNIT_X).x;
			Item.Item grass = new Item.Grass(
				grass_width,
				grass_height,
				grass_scale);
			grass.pos = grass_pos;
			items.add(grass);
			if (grass_x_rel > 1) {
				grass_x_rel = 0;
				grass_z_rel += grass_z_step;
			} else {
				grass_x_rel += grass_x_step;
			}
		}
		// Background dandelions.
		for (uint idx = 0; idx < 20; ++idx) {
			double stalk_z = Random.double_range(
				this._scene_bounds.center().z + 0.25 * this._scene_bounds.depth(),
				this._scene_bounds.p2.z);
			Util.Bounds bounds_at_z = this._camera.bounds_at_z(stalk_z);
			double stalk_x = Random.double_range(
				bounds_at_z.p1.x,
				bounds_at_z.p2.x);
			double stalk_y = this.hill_height(stalk_x, stalk_z);
			Util.Vector3 stalk_pos = Util.Vector3(stalk_x, stalk_y, stalk_z);
			double stalk_scale =
				this._camera.transform_vector(stalk_pos, Util.Vector3.UNIT_X).x;
			Item.Item stalk = new Item.Dandelion(stalk_scale);
			stalk.pos = stalk_pos;
			items.add(stalk);
		}
		// In focus dandelions.
		for (uint idx = 0; idx < 5; ++idx) {
			double stalk_z = this._scene_bounds.center().z;
			Util.Bounds bounds_at_z = this._camera.bounds_at_z(stalk_z);
			double stalk_x = Random.double_range(
				bounds_at_z.p1.x,
				bounds_at_z.p2.x);
			double stalk_y = this.hill_height(stalk_x, stalk_z);
			Util.Vector3 stalk_pos = Util.Vector3(stalk_x, stalk_y, stalk_z);
			double stalk_scale =
				this._camera.transform_vector(stalk_pos, Util.Vector3.UNIT_X).x;
			Item.Item stalk = new Item.Dandelion(stalk_scale);
			stalk.pos = stalk_pos;
			items.add(stalk);
		}
		// Foreground dandelions.
		for (uint idx = 0; idx < 5; ++idx) {
			double stalk_z = Random.double_range(
				this._scene_bounds.p1.z,
				this._scene_bounds.center().z - 0.25 * this._scene_bounds.depth());
			Util.Bounds bounds_at_z = this._camera.bounds_at_z(stalk_z);
			double stalk_x = Random.double_range(
				bounds_at_z.p1.x,
				bounds_at_z.p2.x);
			double stalk_y = this.hill_height(stalk_x, stalk_z);
			Util.Vector3 stalk_pos = Util.Vector3(stalk_x, stalk_y, stalk_z);
			double stalk_scale =
				this._camera.transform_vector(stalk_pos, Util.Vector3.UNIT_X).x;
			Item.Item stalk = new Item.Dandelion(stalk_scale);
			stalk.pos = stalk_pos;
			items.add(stalk);
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
		this._scene_bounds = Util.Bounds3(
			-0.5 * width, -0.5 * height, 0,
			0.5 * width, 0.5 * height, 1.5 * width);

		if (this._background != null) {
			this.remove_child(this._background);
		}
		if (this._item_parent != null) {
			this.remove_child(this._item_parent);
		}
		this._background = new Clutter.Actor();
		this._item_parent = new Clutter.Actor();
		this._background.set_size((float) width, (float) height);
		this._item_parent.set_size((float) width, (float) height);
		this.add_child(this._background);
		this.add_child(this._item_parent);

		this.create_camera(width, height);
		this.create_background(width, height);
		this.create_hill();
		this.create_item_actors();
	}

	private void update_item_actor(int idx) {
		if (!this._scene_exists) {
			return;
		}
		ItemActor item_actor = this._items[idx];
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
		item_actor.screen_pos.x = screen_pos.x;
		item_actor.screen_pos.y = screen_pos.y;
		actor.set_position(
			(float) (screen_pos.x + item.bounds.p1.x),
			(float) (screen_pos.y + item.bounds.p1.y));
		actor.set_rotation_angle(
			Clutter.RotateAxis.Z_AXIS,
			Math.PI / 180 * angle);
		actor.set_scale(scale_x / item.scale, scale_y / item.scale);

		// Check if z has changed. If it has, then ensure that the item is
		// sorted.
		double new_z = screen_pos.z;
		int z_change = Util.compare(new_z, item_actor.screen_pos.z);
		item_actor.screen_pos.z = new_z;
		if (z_change != 0) {
			// Update any effects on the item.
			item.effects = this.defocus_effect(item.pos.z);
			// Check to reorder the actor if necessary.
			int next_idx = idx + z_change;
			while (next_idx >= 0 && next_idx < this._items.size) {
				ItemActor next_item_actor = this._items[next_idx];
				int z_diff = Util.compare(next_item_actor.screen_pos.z, new_z);
				if (z_diff == z_change) {
					// Swap within the children of this actor (only need to do
					// this once at the end).
					if (z_change < 0) {
						this._item_parent.set_child_below_sibling(
							item_actor.actor,
							next_item_actor.actor);
					} else {
						this._item_parent.set_child_above_sibling(
							item_actor.actor,
							next_item_actor.actor);
					}
					break;
				} else {
					// Swap entries.
					this._items[next_idx] = this._items[idx];
					this._items[idx] = next_item_actor;
					// Move to the next pair to compare.
					idx += z_change;
					next_idx = idx + z_change;
				}
			}
		}
	}

	// On a resize, we have to basically recreate the entire scene.
	private void on_resize(float new_width, float new_height) {
		this.create_scene((double) new_width, (double) new_height);
	}

	private void on_step() {
	}
}

}

