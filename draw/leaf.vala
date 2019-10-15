namespace Dandy.Draw {

using Util;

// Leafs have a stem, a number of leaflets along the stem, and veins drawn
// on the leaflets.
public struct LeafParams {
	StemParams stem;
	LeafletsParams leaflets;
	VeinsParams veins;

	public static LeafParams generate() {
		double stem_droop = Random.double_range(0.2, 0.6);
		double stem_angle_sign = Random.boolean() ? 1 : -1;
		double stem_angle =
			stem_angle_sign * stem_droop * 0.5 * Math.PI
			* Random.double_range(0.9, 1.1)
			+ 0.5 * Math.PI;
		double stem_len = Random.double_range(200, 400);
		double stem_diam = 7 + 0.008 * stem_len * Random.double_range(0.9, 1.1);

		double leaflet_width = Random.double_range(32, 96);
		double leaflet_tip_len_rel = Random.double_range(1, 2);
		uint leaflet_count = (uint) (Math.ceil(stem_len / 48) - leaflet_tip_len_rel);

		return LeafParams() {
			stem = StemParams() {
				droop = stem_droop,
				angle = stem_angle,
				len = stem_len,
				diam_start = stem_diam,
				diam_end = 0,
				seg_count = 64
			},
			leaflets = LeafletsParams() {
				shade = random_sym(0.059),
				count = leaflet_count,
				len_var = 0.2,
				width = leaflet_width,
				width_var = 0.1,
				waist_ratio = 0.8,
				peak_strength = 0.5,
				tip_len_rel = leaflet_tip_len_rel,
				tip_strength = Random.double_range(0, 0.05)
			},
			veins = VeinsParams() {
				count = 8 * leaflet_count,
				len = 0.4 * leaflet_width,
				len_var = 0.3,
				base_strength = 0.1,
				base_strength_var = 0.2,
				tip_curvature = 0.5,
				tip_curvature_var = 0.4
			}
		};
	}

	public Bounds bounds() {
		Vector slope = Vector.polar(1, -this.stem.angle);
		double padding = 8;
		double leaflet_padding =
			(this.stem.diam_start
				+ this.leaflets.width * (1 + this.leaflets.width_var))
			* (1 + this.leaflets.width_var);
		double x1 = -0.5 * this.stem.diam_start - leaflet_padding - padding;
		double x2 = -x1;
		double y_offset = this.stem.len * slope.y * double.min(
			1f / (4 * this.stem.droop),
			1 - this.stem.droop);
		double y1 = y_offset - leaflet_padding - padding;
		double y2 = 0.5 * this.stem.diam_start + padding;
		double x_offset = slope.x * this.stem.len;
		if (slope.x < 0) {
			x1 += x_offset;
		} else {
			x2 += x_offset;
		}
		return Bounds(x1, y1, x2, y2);
	}

	public static Vector root_pos() {
		return Vector(0, 0);
	}
}

public struct LeafletsParams {
	double shade;
	uint count;
	double len_var;
	double width;
	double width_var;
	double waist_ratio;
	double peak_strength;
	double tip_len_rel;
	double tip_strength;

	public static Orbit.OffsetParameterization envelope(LeafletsParams leaflets) {
		return (t) => 4 * leaflets.width * t * (1 - t);
	}
}

public struct VeinsParams {
	uint count;
	double len;
	double len_var;
	double base_strength;
	double base_strength_var;
	double tip_curvature;
	double tip_curvature_var;
}

public struct LeafDetails {
	LeafletDetails[] leaflets_left;
	LeafletDetails[] leaflets_right;
	VeinDetails[] veins;

	public static LeafDetails generate(LeafParams leaf) {
		LeafDetails details = LeafDetails() {
			leaflets_left = LeafletDetails.generate(leaf.leaflets, true),
			leaflets_right = LeafletDetails.generate(leaf.leaflets, false),
			veins = VeinDetails.generate(leaf.leaflets, leaf.veins)
		};
		return details;
	}
}

public struct LeafletDetails {
	double t_prev; // The ts indicate points along the stem.
	double t_mid;
	double t_next;
	double u_prev; // The us give the width of the leaf at those points.
	double u_mid;
	double u_next;

	public static LeafletDetails[] generate(
			LeafletsParams leaflets,
			bool is_left) {
		LeafletDetails[] details = new LeafletDetails[leaflets.count];
		Orbit.OffsetParameterization leaflets_envelope =
			LeafletsParams.envelope(leaflets);
		double t_prev = is_left ? 0 : 1;
		double u_prev = 0;
		for (uint leaflet_idx = 0; leaflet_idx < leaflets.count; ++leaflet_idx) {
			uint corrected_leaflet_idx =
				is_left ? leaflet_idx : leaflets.count - leaflet_idx;
			int shift_sign = is_left ? 1 : -1;
			double t_mid =
				(corrected_leaflet_idx + shift_sign * 0.25
					* (1 + random_sym(leaflets.len_var)))
				/ (leaflets.count + leaflets.tip_len_rel);
			double width = leaflets_envelope(t_mid);
			double t_next =
				(corrected_leaflet_idx + shift_sign * 0.75
					* (1 + random_sym(leaflets.len_var)))
				/ (leaflets.count + leaflets.tip_len_rel);
			double u_mid = leaflets.waist_ratio * 0.5 * width
					* (1 + random_sym(leaflets.width_var));
			double u_next = u_mid
				+ u_mid * (1 / leaflets.waist_ratio - 1)
				* (1 + random_sym(leaflets.width_var));
			if (!is_left) {
				double temp = u_mid;
				u_mid = u_next;
				u_next = temp;
			}
			details[leaflet_idx] = LeafletDetails() {
				t_prev = t_prev, u_prev = u_prev,
				t_mid = t_mid, u_mid = u_mid,
				t_next = t_next, u_next = u_next
			};
			t_prev = t_next;
			u_prev = u_next;
		}
		return details;
	}
}

public struct VeinDetails {
	int dir;
	double len;
	double t_start;
	double t_mid;
	double t_end;

	public static VeinDetails[] generate(
			LeafletsParams leaflets,
			VeinsParams veins) {
		Orbit.OffsetParameterization leaflets_envelope =
			LeafletsParams.envelope(leaflets);
		VeinDetails[] details = new VeinDetails[2 * veins.count];
		for (uint vein_idx = 0; vein_idx < veins.count; ++vein_idx) {
			for (int dir = -1; dir <= 1; ++dir) {
				double t_start =
					(vein_idx + 0.5 + random_sym(0.25) + 0.25 * dir)
					/ veins.count;
				double len = veins.len
					* leaflets_envelope(t_start) / leaflets.width
					* (1 + random_sym(veins.len_var));
				double scale = len / leaflets.width;
				double t_mid = t_start + scale * veins.base_strength
					* (1 + random_sym(veins.base_strength_var));
				double t_end = t_start + scale * veins.tip_curvature
					* (1 + random_sym(veins.tip_curvature_var));
				uint detail_idx = 2 * vein_idx + (dir == -1 ? 0 : 1);
				details[detail_idx] = VeinDetails() {
					dir = dir,
					len = len,
					t_start = t_start,
					t_mid = t_mid,
					t_end = t_end
				};
			}
		}
		return details;
	}
}

// Draws the leaf at the origin.
public void draw_leaf(
		Cairo.Context ctx,
		LeafParams leaf,
		LeafDetails details) {
	Vector root_pos = LeafParams.root_pos();
	ctx.save();
	ctx.translate(root_pos.x, root_pos.y);
	Draw.draw_leaflets(ctx,
		leaf.stem,
		leaf.leaflets,
		details.leaflets_left,
		details.leaflets_right,
		details.veins);
	Draw.draw_stem(ctx, leaf.stem);
	ctx.restore();
}

// Draws the leaflets, assuming root transformations.
public void draw_leaflets(
		Cairo.Context ctx,
		StemParams stem,
		LeafletsParams leaflets,
		LeafletDetails[] leaflet_left_details,
		LeafletDetails[] leaflet_right_details,
		VeinDetails[] vein_details) {
	Orbit stem_orbit = StemParams.orbit(stem);
	Vector start = stem_orbit
		.offset_fixed(leaflet_left_details[0].u_prev)
		.at(leaflet_left_details[0].t_prev);

	ctx.save();
	ctx.new_path();
	ctx.move_to(start.x, start.y);
	foreach (LeafletDetails leaflet_detail in leaflet_left_details) {
		double t0 = leaflet_detail.t_prev;
		double t1 = leaflet_detail.t_mid;
		double t2 = leaflet_detail.t_next;
		double u0 = leaflet_detail.u_prev;
		double u1 = leaflet_detail.u_mid;
		double u2 = leaflet_detail.u_next;
		{
			double t_shift = leaflets.peak_strength * (t1 - t0);
			double u_shift = leaflets.peak_strength * (u1 - u0);
			Vector p0 = stem_orbit.offset_fixed(u0).at(t0);
			Vector p1 = stem_orbit.offset_fixed(u0 - u_shift).at(t0);
			Vector p2 = stem_orbit.offset_fixed(u1).at(t1 - t_shift);
			Vector p3 = stem_orbit.offset_fixed(u1).at(t1);
			ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		}
		{
			double t_shift = leaflets.peak_strength * (t2 - t1);
			double u_shift = leaflets.peak_strength * (u2 - u1);
			Vector p0 = stem_orbit.offset_fixed(u1).at(t1);
			Vector p1 = stem_orbit.offset_fixed(u1).at(t1 + t_shift);
			Vector p2 = stem_orbit.offset_fixed(u2 - u_shift).at(t2);
			Vector p3 = stem_orbit.offset_fixed(u2).at(t2);
			ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		}
	}
	{
		double t0 =
			leaflet_left_details[leaflet_left_details.length - 1].t_next;
		double u0 =
			leaflet_left_details[leaflet_left_details.length - 1].u_next;
		double t1 = 1;
		double u1 = 0;
		double u_shift = leaflets.peak_strength * (u1 - u0);
		Vector p0 = stem_orbit.offset_fixed(u0).at(t0);
		Vector p1 = stem_orbit.offset_fixed(u0 + u_shift).at(t0);
		Vector p2 = stem_orbit.offset_fixed(
			leaflets.tip_strength * leaflets.width).at(t1);
		Vector p3 = stem_orbit.offset_fixed(u1).at(t1);
		ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
	}
	bool first = true;
	foreach (LeafletDetails leaflet_details in leaflet_right_details) {
		double t0 = leaflet_details.t_prev;
		double t1 = leaflet_details.t_mid;
		double t2 = leaflet_details.t_next;
		double u0 = leaflet_details.u_prev;
		double u1 = leaflet_details.u_mid;
		double u2 = leaflet_details.u_next;
		{
			double t_shift = leaflets.peak_strength * (t1 - t0);
			double u_shift = leaflets.peak_strength * (u1 - u0);
			Vector p0 = stem_orbit.offset_fixed(-u0).at(t0);
			Vector p1 = stem_orbit.offset_fixed(-u0).at(t0 + t_shift);
			Vector p2 = stem_orbit.offset_fixed(-u1 + u_shift).at(t1);
			Vector p3 = stem_orbit.offset_fixed(-u1).at(t1);
			if (first) {
				p1 = stem_orbit.offset_fixed(
					-u0 - leaflets.tip_strength * leaflets.width)
					.at(t0);
			}
			ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		}
		{
			double t_shift = leaflets.peak_strength * (t2 - t1);
			double u_shift = leaflets.peak_strength * (u2 - u1);
			Vector p0 = stem_orbit.offset_fixed(-u1).at(t1);
			Vector p1 = stem_orbit.offset_fixed(-u1 + u_shift).at(t1);
			Vector p2 = stem_orbit.offset_fixed(-u2).at(t2 - t_shift);
			Vector p3 = stem_orbit.offset_fixed(-u2).at(t2);
			ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		}
		first = false;
	}
	{
		double t0 =
			leaflet_right_details[leaflet_right_details.length - 1].t_next;
		double u0 =
			leaflet_right_details[leaflet_right_details.length - 1].u_next;
		double t1 = 0;
		double u1 = 0.5 * stem.diam_start;
		double t_shift = leaflets.peak_strength * t0;
		Vector p0 = stem_orbit.offset_fixed(-u0).at(t0);
		Vector p1 = stem_orbit.offset_fixed(-u0).at(t0 + t_shift);
		Vector p2 = stem_orbit.offset_fixed(-u1).at(t1 + t_shift);
		Vector p3 = stem_orbit.offset_fixed(-u1).at(t1);
		ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
	}

	ctx.close_path();

	// Main fill color of the leaf.
	ctx.save();
	double color_shift = leaflets.shade;
	double stem_slope_x = Math.cos(stem.angle);
	double stem_slope_y = -Math.sin(stem.angle);
	Cairo.Pattern grad = new Cairo.Pattern.linear(
		0, 0,
		stem_slope_x * stem.len,
		stem_slope_y * stem.len);
	grad.add_color_stop_rgb(0,
		0.706 + color_shift,
		0.784 + color_shift,
		0.549);
	grad.add_color_stop_rgb(1,
		0.392 + color_shift,
		0.471 + color_shift,
		0.235);
	ctx.set_source(grad);
	ctx.fill_preserve();
	ctx.restore();

	// Shadow of the leaf.
	ctx.save();
	double shadow_grad_scale =
		0.5 * (stem.diam_start + leaflets.width);
	double shadow_grad_offset_x = shadow_grad_scale * stem_slope_y;
	double shadow_grad_offset_y = -shadow_grad_scale * stem_slope_y;
	Cairo.Pattern shadow_grad = new Cairo.Pattern.linear(
		shadow_grad_offset_x, shadow_grad_offset_y,
		-shadow_grad_offset_x, -shadow_grad_offset_y);
	shadow_grad.add_color_stop_rgba(0, 0, 0, 0, 0);
	shadow_grad.add_color_stop_rgba(1, 0, 0, 0, 0.2);
	ctx.set_operator(Cairo.Operator.ATOP);
	ctx.set_source(shadow_grad);
	ctx.fill_preserve();
	ctx.restore();

	ctx.save();
	ctx.clip_preserve();

	// Outline of the leaf.
	ctx.save();
	ctx.set_source_rgba(1, 1, 1, 0.08);
	ctx.set_line_width(1);
	ctx.stroke_preserve();
	ctx.set_line_width(2);
	ctx.stroke_preserve();
	ctx.set_line_width(3);
	ctx.stroke_preserve();
	ctx.restore();

	Draw.draw_veins(ctx, stem, vein_details);

	ctx.restore();

	ctx.restore();
}

// Draws the veins, assuming root transformations.
public void draw_veins(
		Cairo.Context ctx,
		StemParams stem,
		VeinDetails[] vein_details) {
	Orbit stem_orbit = StemParams.orbit(stem);
	ctx.save();
	ctx.new_path();
	foreach (VeinDetails vein_detail in vein_details) {
		double t0 = vein_detail.t_start;
		double t1 = vein_detail.t_mid;
		double t2 = vein_detail.t_end;
		double u0 = 0;
		double u1 = u0;
		double u2 = vein_detail.dir * vein_detail.len;
		Vector p0 = stem_orbit.offset_fixed(u0).at(t0);
		Vector p1 = stem_orbit.offset_fixed(u1).at(t1);
		Vector p2 = stem_orbit.offset_fixed(u2).at(t2);
		ctx.move_to(p0.x, p0.y);
		ctx.curve_to(p1.x, p1.y, p1.x, p1.y, p2.x, p2.y);
	}

	ctx.set_line_width(1);
	ctx.set_line_cap(Cairo.LineCap.ROUND);
	ctx.set_source_rgba(1, 1, 1, 0.06);
	ctx.stroke();
	ctx.restore();
}

}

