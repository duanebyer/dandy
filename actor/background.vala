namespace Dandy.Actor {

using Dandy;

public class Background : Clutter.Actor {
	private Gee.ArrayList<Item> _items;
	private Clutter.Actor _background;
	private Clutter.Actor _item_parent;
	private Util.Camera _camera;
	private TimeoutSource _timer;
	private bool _scene_exists;

	private Util.Bounds3 _scene_bounds;
	// TODO: Rename this to better reflect that this is the z at which the main
	// part of the scene is located.
	private double _scene_focus_z;
	private double _hill_curvature;
	private Util.Vector3 _hill_vertex;

	private double hill_height(double x, double z) {
		return this._hill_vertex.y + this._hill_curvature * (
			Util.square((this._hill_vertex.x - x) / this._scene_bounds.width())
			+ Util.square((this._hill_vertex.z - z) / this._scene_bounds.depth()));
	}

	public Background() {
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
		pos.y += 0.7 * this._scene_bounds.height();
		this._camera = new Util.Camera(
			pos,
			7 * Math.PI / 180,
			60 * Math.PI / 180,
			near, far,
			Util.Bounds(0, 0, viewport_width, viewport_height));
		this._camera.focal_plane = this._scene_focus_z;
	}

	private void create_background(double width, double height) {
		int pix_width = (int) Math.ceil(width);
		int pix_height = (int) Math.ceil(height);
		Draw.SkyParams sky_params = Draw.SkyParams.generate(pix_width, pix_height);
		Draw.SkyDetails sky_details = Draw.SkyDetails.generate(sky_params);
		Cairo.ImageSurface image = new Cairo.ImageSurface(
			DrawUtil.FORMAT_CAIRO,
			pix_width,
			pix_height);
		Cairo.Context ctx = new Cairo.Context(image);
		ctx.save();
		Draw.draw_sky(ctx, sky_params, sky_details);
		ctx.restore();
		image.flush();

		Cogl.Texture tex = new Cogl.Texture.from_data(
			(uint) pix_width, (uint) pix_height,
			// TODO: Think about what texture flags should be used here.
			Cogl.TextureFlags.NONE,
			DrawUtil.FORMAT_COGL,
			DrawUtil.FORMAT_COGL,
			image.get_stride(),
			image.get_data());
		DrawUtil.texture_blur_stack(tex, 2);
		uint tex_stride = DrawUtil.FORMAT_SIZE * pix_width;
		uint8[] tex_data = new uint8[tex_stride * pix_height];
		tex.get_data(DrawUtil.FORMAT_COGL, tex_stride, tex_data);

		Clutter.Image content = new Clutter.Image();
		content.set_data(
			tex_data,
			DrawUtil.FORMAT_COGL,
			pix_width, pix_height,
			tex_stride);

		this._background.set_content(content);
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
		this._items = this.generate_items();
		foreach (Item item in this._items) {
			this._item_parent.add_child(item);
			item.update();
		}
	}

	private Gee.ArrayList<Item> generate_items() {
		Gee.ArrayList<Item> items = new Gee.ArrayList<Item>();
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
			double grass_scale =
				this._camera.transform_vector(grass_pos, Util.Vector3.UNIT_X).x;
			double z_scale = Math.fabs(
				this._camera.transform_vector(grass_pos, Util.Vector3.UNIT_Z).y
				/ grass_scale);
			double grass_width = grass_x_step * bounds_at_z.width();
			double grass_height = grass_z_step * this._scene_bounds.depth() * z_scale;
			Item grass = new Grass(
				this._camera,
				grass_width,
				grass_height,
				grass_scale);
			grass.world_pos = grass_pos;
			items.add(grass);
			if (grass_x_rel > 1) {
				grass_x_rel = 0;
				grass_z_rel += grass_z_step;
			} else {
				grass_x_rel += grass_x_step;
			}
		}
		// Background dandelions.
		for (uint idx = 0; idx < 60; ++idx) {
			double back_depth = this._scene_bounds.p2.z - this._scene_focus_z;
			double stalk_z = Random.double_range(
				this._scene_focus_z + 0.35 * back_depth,
				this._scene_bounds.p2.z);
			Util.Bounds bounds_at_z = this._camera.bounds_at_z(stalk_z);
			double stalk_x = Random.double_range(
				bounds_at_z.p1.x,
				bounds_at_z.p2.x);
			double stalk_y = this.hill_height(stalk_x, stalk_z);
			Util.Vector3 stalk_pos = Util.Vector3(stalk_x, stalk_y, stalk_z);
			double stalk_scale =
				this._camera.transform_vector(stalk_pos, Util.Vector3.UNIT_X).x;
			double len = (idx % 2 == 0 ? 200 : 450) * (1 + Util.random_sym(0.3));
			Item stalk = new Dandelion(this._camera, len, stalk_scale);
			stalk.world_pos = stalk_pos;
			items.add(stalk);
		}
		// In focus dandelions.
		uint dandelion_focus_count = 6;
		for (uint idx = 0; idx < dandelion_focus_count; ++idx) {
			double stalk_z = this._scene_focus_z;
			Util.Bounds bounds_at_z = this._camera.bounds_at_z(stalk_z);
			double delta_x = bounds_at_z.width() / dandelion_focus_count;
			double stalk_x = bounds_at_z.p1.x + idx * delta_x
				+ Random.double_range(0, delta_x);
			double stalk_y = this.hill_height(stalk_x, stalk_z);
			Util.Vector3 stalk_pos = Util.Vector3(stalk_x, stalk_y, stalk_z);
			double stalk_scale =
				this._camera.transform_vector(stalk_pos, Util.Vector3.UNIT_X).x;
			double len = 350 * (1 + Util.random_sym(0.4));
			Item stalk = new Dandelion(this._camera, len, stalk_scale);
			stalk.world_pos = stalk_pos;
			items.add(stalk);
		}
		// Foreground dandelions.
		for (uint idx = 0; idx < 6; ++idx) {
			double front_depth = this._scene_focus_z - this._scene_bounds.p1.z;
			double stalk_z = Random.double_range(
				this._scene_bounds.p1.z,
				this._scene_focus_z - 0.25 * front_depth);
			Util.Bounds bounds_at_z = this._camera.bounds_at_z(stalk_z);
			double stalk_x = bounds_at_z.p1.x + Random.double_range(
				0, 0.15 * bounds_at_z.width());
			if (Random.boolean()) {
				stalk_x = bounds_at_z.center().x - stalk_x;
			}
			double stalk_y = this.hill_height(stalk_x, stalk_z);
			Util.Vector3 stalk_pos = Util.Vector3(stalk_x, stalk_y, stalk_z);
			double stalk_scale =
				this._camera.transform_vector(stalk_pos, Util.Vector3.UNIT_X).x;
			double len = 400 * (1 + Util.random_sym(0.4));
			Item stalk = new Dandelion(this._camera, len, stalk_scale);
			stalk.world_pos = stalk_pos;
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
			0.5 * width, 0.5 * height, 2.5 * width);
		this._scene_focus_z = this._scene_bounds.p1.z
			+ 0.3 * this._scene_bounds.depth();

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

	// On a resize, we have to basically recreate the entire scene.
	private void on_resize(float new_width, float new_height) {
		this.create_scene((double) new_width, (double) new_height);
	}

	private void on_step() {
	}
}

}

