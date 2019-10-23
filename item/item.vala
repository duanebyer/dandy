namespace Dandy.Item {

// The base class for objects in the scene that are part of the simulation.
// Items can interact with wind, gravity, and have effects due to being out of
// focus, and so on.
public class Item : Object {
	private Util.Vector3 _pos;
	private double _angle;
	private Util.Bounds _bounds;
	private BillboardMode _billboard_mode;
	// Drawing is done in three stages:
	// * The item is drawn to the `_image` surface, on the creation of the item.
	// * Then, whenever the canvas is invalidated:
	//   * The `_image` surface is copied to `_image_effects`.
	//   * Various effects are applied to `_image_effects` (such as defocus)
	//     through direct pixel manipulation.
	//   * The `_image_effects` surface is drawn to the canvas.
	private Effects _effects;
	private double _effect_padding;
	private Cairo.ImageSurface _image;
	private Cairo.ImageSurface _image_effects;
	private double _scale;
	private Clutter.Canvas _canvas;

	public delegate void DrawMethod(Cairo.Context ctx);

	public enum BillboardMode {
		FACING_CAMERA,
		UPRIGHT
	}

	public struct Effects {
		double blur_radius;
		double tint;
	}

	public Util.Vector3 pos {
		get { return this._pos; }
		set { this._pos = value; }
	}

	public double angle {
		get { return this._angle; }
		set { this._angle = value; }
	}

	public Util.Bounds bounds {
		get { return this._bounds; }
	}

	public double scale {
		get { return this._scale; }
	}

	public Effects effects {
		get { return this._effects; }
		set {
			this._effects = value;
			this.update_effects();
		}
	}

	public Clutter.Canvas canvas {
		get { return this._canvas; }
	}

	public BillboardMode billboard_mode {
		get { return this._billboard_mode; }
		set { this._billboard_mode = value; }
	}

	private void update_effects() {
		// Update the padding to be appropriate.
		this._effect_padding = this._effects.blur_radius;
		int new_width = (int) Math.ceil(
			this._image.get_width() + 2 * this._effect_padding);
		int new_height = (int) Math.ceil(
			this._image.get_height() + 2 * this._effect_padding);
		if (this._image_effects == null
				|| new_width > this._image_effects.get_width()
				|| new_height > this._image_effects.get_height()) {
			this._image_effects = new Cairo.ImageSurface(
				Cairo.Format.ARGB32,
				new_width,
				new_height);
		}

		// Check that there is a canvas to draw to.
		if (this._canvas != null) {
			// Copy the image over.
			Cairo.Context ctx = new Cairo.Context(this._image_effects);
			ctx.set_operator(Cairo.Operator.SOURCE);
			// First clear the existing image.
			ctx.set_source_rgba(0, 0, 0, 0);
			ctx.paint();
			// Then copy the new one over.
			ctx.set_source_surface(
				this._image,
				this._effect_padding,
				this._effect_padding);
			ctx.rectangle(
				this._effect_padding,
				this._effect_padding,
				this._image.get_width(),
				this._image.get_height());
			ctx.fill();

			// Now apply our effects!
			// TODO: Actually apply the effects.

			// Resize the canvas, and also make sure to invalidate it.
			// TODO: Avoid resizing the canvas if possible.
			if (!this._canvas.set_size(new_width, new_height)) {
				this._canvas.invalidate();
			}
		}
	}

	private void draw_canvas(Cairo.Context ctx) {
		ctx.save();
		ctx.set_source_surface(this._image_effects, 0, 0);
		ctx.set_operator(Cairo.Operator.SOURCE);
		ctx.paint();
		ctx.restore();
	}

	protected void draw(Util.Bounds bounds, double scale, DrawMethod draw) {
		this._scale = scale;
		this._bounds = Util.Bounds(0, 0, 0, 0);
		// Scale by the scale factor.
		bounds.p1 = bounds.p1.scale(scale);
		bounds.p2 = bounds.p2.scale(scale);
		// Round up the size of the bounds to the nearest pixel.
		this._bounds.p1.x = Math.floor(Math.fmin(bounds.p1.x, bounds.p2.x));
		this._bounds.p1.y = Math.floor(Math.fmin(bounds.p1.y, bounds.p2.y));
		this._bounds.p2.x = Math.ceil(Math.fmax(bounds.p1.x, bounds.p2.x));
		this._bounds.p2.y = Math.ceil(Math.fmax(bounds.p1.y, bounds.p2.y));
		double width = this._bounds.width();
		double height = this._bounds.height();

		this._billboard_mode = BillboardMode.FACING_CAMERA;

		this._effects = Effects() {
			blur_radius = 0,
			tint = 0
		};
		this._image = new Cairo.ImageSurface(
			Cairo.Format.ARGB32,
			(int) width,
			(int) height);
		Cairo.Context image_ctx = new Cairo.Context(this._image);
		image_ctx.save();
		image_ctx.translate(-this._bounds.p1.x, -this._bounds.p1.y);
		image_ctx.scale(this._scale, this._scale);
		draw(image_ctx);
		image_ctx.restore();

		this._canvas = new Clutter.Canvas() {
			width = (int) width,
			height = (int) height
		};
		this._canvas.draw.connect((canvas, ctx, w, h) => {
			this.draw_canvas(ctx);
			return false;
		});
		this.update_effects();
	}
}

}

