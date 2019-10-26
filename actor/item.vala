namespace Dandy.Actor {

using Dandy;

// The base class for objects in the scene that are part of the simulation.
// Items can interact with wind, gravity, and have effects due to being out of
// focus, and so on.
public class Item : Clutter.Actor {
	private Util.Vector3 _world_pos;
	private double _world_rot;
	private double _screen_z;

	private Util.Camera _camera;

	// Drawing is done in the following stages:
	// * A cairo surface is created and drawn to using cairo.
	// * The data is copied to a COGL texture.
	// * Effects are performed on the COGL texture.
	// * The COGL texture is copied to a Clutter image.
	// The base image is the image before any effects have been applied.
	private Cairo.ImageSurface _base_image;
	private Clutter.Image _image;

	private Util.Bounds _base_bounds;
	private Util.Bounds _bounds;
	private double _resolution_factor;
	private BillboardMode _billboard_mode;

	public delegate void DrawMethod(Cairo.Context ctx);

	public enum BillboardMode {
		FACING_CAMERA,
		UPRIGHT
	}

	public Util.Vector3 world_pos {
		get { return this._world_pos; }
		set {
			this._world_pos = value;
			this.update_actor_position();
			this.update_actor_scale();
		}
	}

	public double world_rot {
		get { return this._world_rot; }
		set {
			this._world_rot = value;
			this.update_actor_rotation();
		}
	}

	public BillboardMode billboard_mode {
		get { return this._billboard_mode; }
		set {
			this._billboard_mode = value;
			this.update_actor_scale();
		}
	}

	public Util.Camera camera {
		get { return this._camera; }
		set {
			this._camera = value;
			this.update_actor_position();
			this.update_actor_rotation();
			this.update_actor_scale();
		}
	}

	public Item(Util.Camera camera) {
		this._world_pos = Util.Vector3(0, 0, 0);
		this._world_rot = 0;
		this._screen_z = 0;

		this._camera = camera;

		this._base_image = new Cairo.ImageSurface(DrawUtil.FORMAT_CAIRO, 0, 0);
		this._image = new Clutter.Image();

		this._base_bounds = Util.Bounds(0, 0, 0, 0);
		this._bounds = Util.Bounds(0, 0, 0, 0);
		this._resolution_factor = 1;
		this._billboard_mode = BillboardMode.FACING_CAMERA;
		
		base.set_content(this._image);
		base.set_size(0, 0);
		base.set_pivot_point(0, 0);

		base.parent_set.connect((actor, old_parent) => {
			if (old_parent == null) {
				this.update_image();
			}
			this.update_actor_ordering();
		});
	}

	public void update() {
		this.update_actor_position();
		this.update_actor_rotation();
		this.update_actor_scale();
	}

	protected void update_base_image(
			Util.Bounds base_bounds,
			double resolution_factor,
			DrawMethod draw_method) {
		this._resolution_factor = resolution_factor;
		// Modify the bounds to account for the modified resolution and to align
		// with pixels.
		base_bounds.p1 = base_bounds.p1.scale(this._resolution_factor);
		base_bounds.p2 = base_bounds.p2.scale(this._resolution_factor);
		this._base_bounds = base_bounds.pixelize();

		int base_width = (int) this._base_bounds.width();
		int base_height = (int) this._base_bounds.height();

		// Create a new base image and draw to it.
		this._base_image = new Cairo.ImageSurface(
			DrawUtil.FORMAT_CAIRO,
			base_width, base_height);
		Cairo.Context ctx = new Cairo.Context(this._base_image);
		ctx.save();
		ctx.translate(-this._base_bounds.p1.x, -this._base_bounds.p1.y);
		ctx.scale(this._resolution_factor, this._resolution_factor);
		draw_method(ctx);
		ctx.restore();
		this._base_image.flush();

		// Update the image.
		this.update_image();
	}

	private void update_image() {
		// If this actor doesn't even have a parent yet, then there is no need
		// to update the image. It will automatically be updated when a parent
		// is added.
		if (this.get_parent() == null) {
			return;
		}

		double defocus = 0;
		double z = this._world_pos.z;
		double focal_plane = this._camera.focal_plane;
		double back_depth = this._camera.far - focal_plane;
		double front_depth = focal_plane - this._camera.near;
		if (z < focal_plane) {
			defocus = (focal_plane - z) / front_depth;
		} else if (z > focal_plane) {
			defocus = (z - focal_plane) / back_depth;
		}

		double blur_radius = 7 * Math.fabs(defocus) * this._resolution_factor;
		double tint = -0.4 * Math.fabs(defocus);
		double padding = 2 * blur_radius;
		this._bounds = this._base_bounds.pad(padding).pixelize();

		int base_width = this._base_image.get_width();
		int base_height = this._base_image.get_height();
		int base_stride = this._base_image.get_stride();
		unowned uint8[] base_data = this._base_image.get_data();

		uint tex_width = (uint) this._bounds.width();
		uint tex_height = (uint) this._bounds.height();
		int offset_x = (int) (this._base_bounds.p1.x - this._bounds.p1.x);
		int offset_y = (int) (this._base_bounds.p1.y - this._bounds.p1.y);

		// TODO: Use experimental API to modify the image texture directly, if
		// possible.
		Cogl.Texture tex = new Cogl.Texture.with_size(
			tex_width, tex_height,
			// TODO: Determine which texture flags to use (mip-maps shouldn't be
			// generated).
			Cogl.TextureFlags.NONE,
			DrawUtil.FORMAT_COGL);

		// Copy the image to the center of the texture.
		tex.set_region(
			0, 0,
			offset_x, offset_y,
			(uint) base_width, (uint) base_height,
			base_width, base_height,
			DrawUtil.FORMAT_COGL,
			base_stride,
			base_data);

		// TODO: Set a minimum requirement on blur radius (blur_radius >= 0.5).
		if (blur_radius != 0) {
			DrawUtil.texture_blur_stack(tex, blur_radius);
		}
		if (tint != 0) {
			DrawUtil.texture_tint(tex, tint);
		}

		// Copy the data from the texture to the image.
		uint tex_data_stride = DrawUtil.FORMAT_SIZE * tex_width;
		uint8[] tex_data = new uint8[tex_data_stride * tex_height];
		tex.get_data(DrawUtil.FORMAT_COGL, tex_data_stride, tex_data);
		this._image.set_data(
			tex_data,
			DrawUtil.FORMAT_COGL,
			tex_width, tex_height,
			tex_data_stride);

		// Update the actor.
		base.set_size(tex_width, tex_height);
		base.set_pivot_point(
			(float) (-this._bounds.p1.x / this._bounds.width()),
			(float) (-this._bounds.p1.y / this._bounds.height()));
		this.update_actor_scale();
	}

	private void update_actor_position() {
		// Find the parameters describing how the item should appear.
		Util.Vector3 screen_pos = this._camera.transform(this._world_pos);
		base.set_position(
			(float) (screen_pos.x + this._bounds.p1.x),
			(float) (screen_pos.y + this._bounds.p1.y));
		double old_screen_z = this._screen_z;
		this._screen_z = screen_pos.z;
		if (old_screen_z != this._screen_z) {
			this.update_image();
			this.update_actor_ordering();
		}
	}

	private void update_actor_rotation() {
		base.set_rotation_angle(
			Clutter.RotateAxis.Z_AXIS,
			Math.PI / 180 * this._world_rot);
	}

	private void update_actor_scale() {
		double scale_x = this._camera.transform_vector(
			this._world_pos,
			Util.Vector3.UNIT_X).x;
		double scale_y = scale_x;
		if (this._billboard_mode == BillboardMode.FACING_CAMERA) {
			scale_y = scale_x;
		} else if (this._billboard_mode == BillboardMode.UPRIGHT) {
			scale_y = this._camera.transform_vector(
				this._world_pos,
				Util.Vector3.UNIT_Y).y;
		}
		base.set_scale(
			scale_x / this._resolution_factor,
			scale_y / this._resolution_factor);
	}

	private void update_actor_ordering() {
		Clutter.Actor parent = base.get_parent();
		if (parent == null) {
			return;
		}
		Clutter.Actor current;
		// Check forward to make sure that this item shouldn't be any higher
		// than it is.
		current = this;
		while (current != null) {
			current = current.get_next_sibling();
			Item item = current as Item;
			if (item != null && item._screen_z < this._screen_z) {
				break;
			}
		}
		if (current != null) {
			parent.set_child_below_sibling(this, current);
		} else {
			parent.set_child_above_sibling(this, null);
		}

		// Check in reverse to make sure that this item shouldn't be any lower
		// either.
		current = this;
		while (current != null) {
			current = current.get_previous_sibling();
			Item item = current as Item;
			if (item != null && item._screen_z >= this._screen_z) {
				break;
			}
		}
		if (current != null) {
			parent.set_child_above_sibling(this, current);
		} else {
			parent.set_child_below_sibling(this, null);
		}
	}
}

}

