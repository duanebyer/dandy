using Dandy.Draw;

public class Dandy.Background : Clutter.Actor {

	private Clutter.Canvas _canvas;
	private FluffParams _fluff_params;
	private FluffDetails _fluff_details;
	private StalkParams _stalk_params;
	private StalkDetails _stalk_details;
	private LeafParams _leaf_params;
	private LeafDetails _leaf_details;
	private GrassParams _grass_params;
	private GrassDetails _grass_details;
	private TimeoutSource _timer;

	public Background() {
		Object();
	}

	private void _on_resize(float new_width, float new_height) {
		this._canvas.set_size((int) new_width, (int) new_height);
	}

	private void _on_draw(Cairo.Context ctx) {
		Util.Bounds fluff_bounds = this._fluff_params.bounds();
		Util.Bounds stalk_bounds = this._stalk_params.bounds();
		Util.Bounds leaf_bounds = this._leaf_params.bounds();
		Util.Bounds grass_bounds = this._grass_params.bounds();

		ctx.save();
		ctx.set_source_rgb(0, 0, 0);
		ctx.paint();
		ctx.translate(100, 300);
		draw_fluff(ctx, this._fluff_params, this._fluff_details);
		ctx.translate(200, 0);
		draw_stalk(ctx, this._stalk_params, this._stalk_details);
		ctx.translate(200, 0);
		draw_leaf(ctx, this._leaf_params, this._leaf_details);
		ctx.translate(200, 0);
		draw_grass(ctx, this._grass_params, this._grass_details);
		ctx.restore();

		ctx.save();
		ctx.set_source_rgb(1, 0, 0);
		ctx.translate(100, 300);
		ctx.rectangle(
			fluff_bounds.x1,
			fluff_bounds.y1,
			fluff_bounds.x2 - fluff_bounds.x1,
			fluff_bounds.y2 - fluff_bounds.y1);
		ctx.stroke();

		ctx.translate(200, 0);
		ctx.rectangle(
			stalk_bounds.x1,
			stalk_bounds.y1,
			stalk_bounds.x2 - stalk_bounds.x1,
			stalk_bounds.y2 - stalk_bounds.y1);
		ctx.stroke();

		ctx.translate(200, 0);
		ctx.rectangle(
			leaf_bounds.x1,
			leaf_bounds.y1,
			leaf_bounds.x2 - leaf_bounds.x1,
			leaf_bounds.y2 - leaf_bounds.y1);
		ctx.stroke();

		ctx.translate(200, 0);
		ctx.rectangle(
			grass_bounds.x1,
			grass_bounds.y1,
			grass_bounds.x2 - grass_bounds.x1,
			grass_bounds.y2 - grass_bounds.y1);
		ctx.stroke();

		ctx.restore();
	}

	private void _onTimer() {
		//this._fluff_params.tilt += 0.005 * Math.PI;
		//this._fluff_params.roll += 0.005 * Math.PI;
		//this._canvas.invalidate();
	}

	construct {
		this.allocation_changed.connect((a) => {
			this._on_resize(a.get_width(), a.get_height());
		});

		this._stalk_params = StalkParams.generate();
		this._stalk_details = StalkDetails.generate(this._stalk_params);
		this._fluff_params = FluffParams.generate();
		this._fluff_details = FluffDetails.generate(this._fluff_params);
		this._leaf_params = LeafParams.generate();
		this._leaf_details = LeafDetails.generate(this._leaf_params);
		this._grass_params = GrassParams.generate();
		this._grass_details = GrassDetails.generate(this._grass_params);

		this._canvas = new Clutter.Canvas() {
			width = (int) this.width,
			height = (int) this.height 
		};
		this._canvas.draw.connect((ctx) => {
			this._on_draw(ctx);
			return true;
		});
		this._canvas.invalidate();

		this._timer = new TimeoutSource(30);
		this._timer.set_callback(() => {
			this._onTimer();
			return Source.CONTINUE;
		});
		this._timer.attach(null);

		this.set_content(this._canvas);
	}
}

