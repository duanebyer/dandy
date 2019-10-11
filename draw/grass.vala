namespace Dandy.Draw {

using Util;

public struct GrassParams {
	BladeParams blade;
	LaminasParams laminas;

	public static GrassParams generate() {
		double diam = 24 * (1 + Util.random_sym(0.1));
		double len = 96 * (1 + Util.random_sym(0.8));
		double droop = 0.2 * (1 + Util.random_sym(0.2));
		double angle = 0.5 * Math.PI + Util.random_sym(0.1 * Math.PI);
		return GrassParams() {
			blade = BladeParams() {
				spacing = 16,
				diam = diam,
				len = len,
				droop = droop,
				angle = angle,
				seg_count = 25
			},
			laminas = LaminasParams() {
				count = 4,
				len = 0.4,
				len_var = 0.5,
				seg_count = 25
			}
		};
	}

	public Bounds bounds() {
		double slope_x = Math.cos(this.blade.angle);
		double slope_y = -Math.sin(this.blade.angle);
		double padding = 4;
		double x1 = -0.5 * this.blade.diam - padding;
		double x2 = -x1;
		double y_offset = -0.5 * this.blade.diam
			+ this.blade.len * slope_y * min(
				1f / (4 * this.blade.droop),
				1 - this.blade.droop);
		double y1 = 0.5 * this.blade.diam + padding;
		double y2 = y_offset - padding;
		double x_offset = slope_x * this.blade.len;
		if (slope_x < 0) {
			x1 += x_offset;
		} else {
			x2 += x_offset;
		}
		return Bounds() {
			x1 = x1, y1 = y1, x2 = x2, y2 = y2
		};
	}

	public static Point root_pos() {
		return Point() { x = 0, y = 0 };
	}
}

public struct BladeParams {
	double shade;
	double spacing;
	double diam;
	double len;
	double droop;
	double angle;
	uint seg_count;

	public static Orbit orbit(BladeParams blade) {
		return Orbit.line_with_droop(
			Math.cos(blade.angle),
			-Math.sin(blade.angle),
			blade.len,
			blade.droop);
	}
}

public struct LaminasParams {
	uint count;
	double len;
	double len_var;
	uint seg_count;
}

public struct GrassDetails {
	LaminaDetails[] laminas;

	public static GrassDetails generate(GrassParams grass) {
		return GrassDetails() {
			laminas = LaminaDetails.generate(grass.blade, grass.laminas)
		};
	}
}

public struct LaminaDetails {
	double u;
	double t_start;
	double t_end;

	public static LaminaDetails[] generate(
			BladeParams blade,
			LaminasParams laminas) {
		LaminaDetails[] details = new LaminaDetails[laminas.count];
		for (uint lamina_idx = 0; lamina_idx < laminas.count; ++lamina_idx) {
			double offset = (blade.diam / laminas.count)
				* (0.5 * laminas.count - lamina_idx - Random.next_double());
			double len = laminas.len * (1 + Util.random_sym(laminas.len_var));
			double t_start = Random.double_range(0, 1 - len);
			double t_end = t_start + len;
			details[lamina_idx] = LaminaDetails() {
				u = offset,
				t_start = t_start,
				t_end = t_end
			};
		}
		return details;
	}
}

// Draws the grass at the origin.
public void draw_grass(
		Cairo.Context ctx,
		GrassParams grass,
		GrassDetails details) {
	Point root_pos = GrassParams.root_pos();
	ctx.save();
	ctx.translate(root_pos.x, root_pos.y);
	Draw.draw_blade(ctx, grass.blade);
	Draw.draw_laminas(ctx, grass.blade, grass.laminas, details.laminas);
	ctx.restore();
}

// Draws the blade, assuming root transformations.
public static void draw_blade(
		Cairo.Context ctx,
		BladeParams blade) {
	Orbit blade_orbit = BladeParams.orbit(blade);
	Orbit.OffsetParameterization offset = (t) => lerp(0.5 * blade.diam, 0, t);
	Orbit blade_offset_left_orbit = blade_orbit.offset(offset)
		.append(blade_orbit.reverse());
	Orbit blade_offset_right_orbit = blade_orbit.offset((t) => -offset(t))
		.append(blade_orbit.reverse());

	ctx.save();

	ctx.new_path();
	DrawUtil.orbit_to(ctx, blade_offset_left_orbit, blade.seg_count);
	ctx.close_path();

	Point grad_end = Point() {
		x = Math.cos(blade.angle) * blade.len,
		y = -Math.sin(blade.angle) * blade.len
	};

	Cairo.Pattern grad_left = new Cairo.Pattern.linear(0, 0, grad_end.x, grad_end.y);
	grad_left.add_color_stop_rgb(0, 0.706 + blade.shade, 0.784 + blade.shade, 0.549);
	grad_left.add_color_stop_rgb(1, 0.392 + blade.shade, 0.471 + blade.shade, 0.235);
	ctx.set_source(grad_left);
	ctx.fill_preserve();

	ctx.restore();

	ctx.save();

	ctx.new_path();
	DrawUtil.orbit_to(ctx, blade_offset_right_orbit, blade.seg_count);
	ctx.close_path();

	Cairo.Pattern grad_right = new Cairo.Pattern.linear(0, 0, grad_end.x, grad_end.y);
	grad_right.add_color_stop_rgb(0, 0.667 + blade.shade, 0.745 + blade.shade, 0.510);
	grad_right.add_color_stop_rgb(1, 0.353 + blade.shade, 0.431 + blade.shade, 0.196);
	ctx.set_source(grad_right);
	ctx.fill_preserve();

	ctx.restore();
}

// Draws the laminas, assuming root transformations.
public void draw_laminas(
		Cairo.Context ctx,
		BladeParams blade,
		LaminasParams laminas,
		LaminaDetails[] lamina_details) {

	Orbit blade_orbit = BladeParams.orbit(blade);
	foreach (LaminaDetails lamina_detail in lamina_details) {
		ctx.save();
		Orbit lamina_orbit = blade_orbit.offset_fixed(lamina_detail.u)
			.rescale(lamina_detail.t_start, lamina_detail.t_end);
		ctx.new_path();
		DrawUtil.orbit_to(ctx, lamina_orbit, laminas.seg_count);
		ctx.set_line_width(1);
		ctx.set_operator(Cairo.Operator.ATOP);
		ctx.set_source_rgba(0, 0, 0, 0.1);
		ctx.stroke();
		ctx.restore();
	}
}

}

