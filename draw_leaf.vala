public class Dandy.DrawLeaf {

	// Leafs have a stem, a number of leaflets along the stem, and veins drawn
	// on the leaflets.
	public struct Params {
		StemParams stem;
		LeafletsParams leaflets;
		VeinsParams veins;
	}

	public struct StemParams {
		double droop;
		double angle;
		double len;
		double diam;
		uint seg_count;
	}

	public struct LeafletsParams {
		uint count;
		double len_var;
		double width;
		double width_var;
		double waist_ratio;
		double peak_strength;
		double tip_len_rel;
		double tip_strength;
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

	public struct Details {
		LeafletDetails[] leaflets_left;
		LeafletDetails[] leaflets_right;
		VeinDetails[] veins;
	}

	public struct LeafletDetails {
		double t_prev; // The ts indicate points along the stem.
		double t_mid;
		double t_next;
		double u_prev; // The us give the width of the leaf at those points.
		double u_mid;
		double u_next;
	}

	public struct VeinDetails {
		int dir;
		double len;
		double t_start;
		double t_mid;
		double t_end;
	}

	public static Params gen_params() {
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

		return Params() {
			stem = StemParams() {
				droop = stem_droop,
				angle = stem_angle,
				len = stem_len,
				diam = stem_diam,
				seg_count = 64
			},
			leaflets = LeafletsParams() {
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

	public static Details gen_details(Params params) {
		Details details = Details() {
			leaflets_left = new LeafletDetails[params.leaflets.count],
			leaflets_right = new LeafletDetails[params.leaflets.count],
			veins = new VeinDetails[2 * params.veins.count]
		};
		Path.OffsetParameterization offset_curve = (t) =>
			0.5 * Util.lerp(params.stem.diam, 0, t);
		Path.OffsetParameterization leaflet_envelope = (t) =>
			4 * params.leaflets.width * t * (1 - t);
		double t_prev = 0;
		double u_prev = offset_curve(0);
		for (uint leaflet_idx = 0; leaflet_idx < params.leaflets.count; ++leaflet_idx) {
			double t_mid =
				(leaflet_idx + 0.25 * (1 + Util.random_sym(params.leaflets.len_var)))
				/ (params.leaflets.count + params.leaflets.tip_len_rel);
			double width = leaflet_envelope(t_mid);
			double t_next =
				(leaflet_idx + 0.75 * (1 + Util.random_sym(params.leaflets.len_var)))
				/ (params.leaflets.count + params.leaflets.tip_len_rel);
			double u_mid =
				offset_curve(t_mid)
				+ params.leaflets.waist_ratio * 0.5 * width
					* (1 + Util.random_sym(params.leaflets.width_var));
			double u_next = u_mid
				+ u_mid * (1 / params.leaflets.waist_ratio - 1)
				* (1 + Util.random_sym(params.leaflets.width_var));
			details.leaflets_left[leaflet_idx] = LeafletDetails() {
				t_prev = t_prev, u_prev = u_prev,
				t_mid = t_mid, u_mid = u_mid,
				t_next = t_next, u_next = u_next
			};
			t_prev = t_next;
			u_prev = u_next;
		}
		t_prev = 1;
		u_prev = 0;
		for (uint leaflet_idx = 0; leaflet_idx < params.leaflets.count; ++leaflet_idx) {
			double t_mid =
				((params.leaflets.count - leaflet_idx)
					- 0.25 * (1 + Util.random_sym(params.leaflets.len_var)))
				/ (params.leaflets.count + params.leaflets.tip_len_rel);
			double width = leaflet_envelope(t_mid);
			double t_next =
				((params.leaflets.count - leaflet_idx)
					- 0.75 * (1 + Util.random_sym(params.leaflets.len_var)))
				/ (params.leaflets.count + params.leaflets.tip_len_rel);
			double u_next =
				offset_curve(t_next)
				+ params.leaflets.waist_ratio * 0.5 * width
					* (1 + Util.random_sym(params.leaflets.width_var));
			double u_mid = u_next
				+ u_next * (1 / params.leaflets.waist_ratio - 1)
				* (1 + Util.random_sym(params.leaflets.width_var));
			details.leaflets_right[leaflet_idx] = LeafletDetails() {
				t_prev = t_prev, u_prev = u_prev,
				t_mid = t_mid, u_mid = u_mid,
				t_next = t_next, u_next = u_next
			};
			t_prev = t_next;
			u_prev = u_next;
		}

		for (uint vein_idx = 0; vein_idx < params.veins.count; ++vein_idx) {
			for (int dir = -1; dir <= 1; ++dir) {
				double t_start =
					(vein_idx + 0.5 + Util.random_sym(0.25) + 0.25 * dir)
					/ params.veins.count;
				double len = params.veins.len
					* leaflet_envelope(t_start) / params.leaflets.width
					* (1 + Util.random_sym(params.veins.len_var));
				double scale = len / params.leaflets.width;
				double t_mid = t_start + scale * params.veins.base_strength
					* (1 + Util.random_sym(params.veins.base_strength_var));
				double t_end = t_start + scale * params.veins.tip_curvature
					* (1 + Util.random_sym(params.veins.tip_curvature_var));
				uint detail_idx = 2 * vein_idx + (dir == -1 ? 0 : 1);
				details.veins[detail_idx] = VeinDetails() {
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

	public static Util.Bounds get_bounds(Params params) {
		double slope_x = Math.cos(params.stem.angle);
		double slope_y = -Math.sin(params.stem.angle);
		double padding = 8;
		double leaflet_padding =
			(params.stem.diam
				+ params.leaflets.width * (1 + params.leaflets.width_var))
			* (1 + params.leaflets.width_var);
		double x1 = -0.5 * params.stem.diam - leaflet_padding - padding;
		double x2 = -x1;
		double y_offset = params.stem.len * slope_y * Util.min(
			1f / (4 * params.stem.droop),
			1 - params.stem.droop);
		double y1 = 0.5 * params.stem.diam + padding;
		double y2 = y_offset - leaflet_padding - padding;
		double x_offset = slope_x * params.stem.len;
		if (slope_x < 0) {
			x1 += x_offset;
		} else {
			x2 += x_offset;
		}
		return Util.Bounds() {
			x1 = x1, y1 = y1, x2 = x2, y2 = y2
		};
	}

	public static Util.Point get_root_pos() {
		return Util.Point() { x = 0, y = 0 };
	}

	private static Path get_stem_path(StemParams stem) {
		double slope_x = Math.cos(stem.angle);
		double slope_y = -Math.sin(stem.angle);
		double len = stem.len;
		double droop = stem.droop;
		return Path.line_with_droop(slope_x, slope_y, len, droop);
	}

	public static void draw(
			Cairo.Context ctx,
			Params params,
			Details details) {
		Util.Point root_pos = DrawLeaf.get_root_pos();
		ctx.save();
		ctx.translate(root_pos.x, root_pos.y);
		DrawLeaf.draw_leaflets(ctx,
			params.stem,
			params.leaflets,
			details.leaflets_left,
			details.leaflets_right,
			details.veins);
		DrawLeaf.draw_stem(ctx, params.stem);
		ctx.restore();
	}

	// Draws the stem, assuming root transformations.
	public static void draw_stem(
			Cairo.Context ctx,
			StemParams stem) {
		// Just steal the `draw_stem` method used when drawing the stalk.
		DrawStalk.StemParams stalk_stem = DrawStalk.StemParams() {
			droop = stem.droop,
			angle = stem.angle,
			len = stem.len,
			diam_start = stem.diam,
			diam_end = 0,
			seg_count = stem.seg_count
		};
		DrawStalk.draw_stem(ctx, stalk_stem);
	}

	// Draws the leaflets, assuming root transformations.
	public static void draw_leaflets(
			Cairo.Context ctx,
			StemParams stem,
			LeafletsParams leaflets,
			LeafletDetails[] leaflet_left_details,
			LeafletDetails[] leaflet_right_details,
			VeinDetails[] vein_details) {
		Path stem_path = DrawLeaf.get_stem_path(stem);
		Util.Point start = stem_path
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
				Util.Point p0 = stem_path.offset_fixed(u0).at(t0);
				Util.Point p1 = stem_path.offset_fixed(u0 - u_shift).at(t0);
				Util.Point p2 = stem_path.offset_fixed(u1).at(t1 - t_shift);
				Util.Point p3 = stem_path.offset_fixed(u1).at(t1);
				ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
			}
			{
				double t_shift = leaflets.peak_strength * (t2 - t1);
				double u_shift = leaflets.peak_strength * (u2 - u1);
				Util.Point p0 = stem_path.offset_fixed(u1).at(t1);
				Util.Point p1 = stem_path.offset_fixed(u1).at(t1 + t_shift);
				Util.Point p2 = stem_path.offset_fixed(u2 - u_shift).at(t2);
				Util.Point p3 = stem_path.offset_fixed(u2).at(t2);
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
			Util.Point p0 = stem_path.offset_fixed(u0).at(t0);
			Util.Point p1 = stem_path.offset_fixed(u0 + u_shift).at(t0);
			Util.Point p2 = stem_path.offset_fixed(
				leaflets.tip_strength * leaflets.width).at(t1);
			Util.Point p3 = stem_path.offset_fixed(u1).at(t1);
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
				Util.Point p0 = stem_path.offset_fixed(-u0).at(t0);
				Util.Point p1 = stem_path.offset_fixed(-u0).at(t0 + t_shift);
				Util.Point p2 = stem_path.offset_fixed(-u1 + u_shift).at(t1);
				Util.Point p3 = stem_path.offset_fixed(-u1).at(t1);
				if (first) {
					p1 = stem_path.offset_fixed(
						-u0 - leaflets.tip_strength * leaflets.width)
						.at(t0);
				}
				ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
			}
			{
				double t_shift = leaflets.peak_strength * (t2 - t1);
				double u_shift = leaflets.peak_strength * (u2 - u1);
				Util.Point p0 = stem_path.offset_fixed(-u1).at(t1);
				Util.Point p1 = stem_path.offset_fixed(-u1 + u_shift).at(t1);
				Util.Point p2 = stem_path.offset_fixed(-u2).at(t2 - t_shift);
				Util.Point p3 = stem_path.offset_fixed(-u2).at(t2);
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
			double u1 = 0.5 * stem.diam;
			double t_shift = leaflets.peak_strength * t0;
			Util.Point p0 = stem_path.offset_fixed(-u0).at(t0);
			Util.Point p1 = stem_path.offset_fixed(-u0).at(t0 + t_shift);
			Util.Point p2 = stem_path.offset_fixed(-u1).at(t1 + t_shift);
			Util.Point p3 = stem_path.offset_fixed(-u1).at(t1);
			ctx.curve_to(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
		}

		ctx.close_path();

		// Main fill color of the leaf.
		ctx.save();
		double color_shift = Util.random_sym(0.059);
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
			0.5 * (stem.diam + leaflets.width);
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

		DrawLeaf.draw_veins(ctx, stem, vein_details);

		ctx.restore();

		ctx.restore();
	}

	public static void draw_veins(
			Cairo.Context ctx,
			StemParams stem,
			VeinDetails[] vein_details) {
		ctx.save();
		Path stem_path = get_stem_path(stem);
		ctx.new_path();
		foreach (VeinDetails vein_detail in vein_details) {
			double t0 = vein_detail.t_start;
			double t1 = vein_detail.t_mid;
			double t2 = vein_detail.t_end;
			double u0 = 0;
			double u1 = u0;
			double u2 = vein_detail.dir * vein_detail.len;
			Util.Point p0 = stem_path.offset_fixed(u0).at(t0);
			Util.Point p1 = stem_path.offset_fixed(u1).at(t1);
			Util.Point p2 = stem_path.offset_fixed(u2).at(t2);
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

