namespace Dandy.Draw {

using Util;

public struct StalkParams {
	public StemParams stem;
	public HeadParams head;

	public static StalkParams generate() {
		double droop = Random.double_range(0, 0.2);
		double angle_sign = Random.boolean() ? 1 : -1;
		double angle =
			angle_sign * droop * 0.5 * Math.PI
			* Random.double_range(0.9, 1.1)
			+ 0.5 * Math.PI;
		double len = Random.double_range(200, 300);
		double diam_end = 11 * Random.double_range(0.9, 1.1);
		double diam_start = diam_end + 0.015 * len * Random.double_range(0.9, 1.1);
		return StalkParams() {
			stem = StemParams() {
				droop = droop,
				angle = angle,
				len = len,
				diam_start = diam_start,
				diam_end = diam_end,
				seg_count = 64
			},
			head = HeadParams() {
				width = 32 * Random.double_range(0.9, 1.1),
				height = 24 * Random.double_range(0.9, 1.1),
				stipples = StipplesParams() {
					spacing = 4,
					diam = 2,
					curvature = 0.7
				},
				bracts = BractsParams() {
					base_width = 16,
					max_offset = 16,
					len = 64,
					count = 6,
					seg_count = 64
				}
			}
		};
	}

	public Bounds bounds() {
		double slope_x = Math.cos(this.stem.angle);
		double slope_y = -Math.sin(this.stem.angle);
		double padding = 8;
		double head_padding =
			0.5 * this.head.width
			+ 0.5 * this.head.height
			+ 0.5 * this.head.bracts.base_width
			+ this.head.bracts.max_offset;
		double x1 = -0.5 * this.stem.diam_start - head_padding - padding;
		double x2 = -x1;
		double y_offset = this.stem.len * slope_y * min(
			1f / (4 * this.stem.droop),
			1 - this.stem.droop);
		double y1 = 0.5 * this.stem.diam_start + padding;
		double y2 = y_offset
			- 0.5 * this.head.width
			- 0.5 * this.head.height
			- padding;
		double x_offset = slope_x * this.stem.len;
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

	public static Point head_pos(StemParams stem) {
		return Point() {
			x = Math.cos(stem.angle) * stem.len,
			y = -Math.sin(stem.angle) * stem.len * (1 - stem.droop)
		};
	}

	public static double head_angle(StemParams stem) {
		return Math.atan2(
			Math.cos(stem.angle),
			Math.sin(stem.angle) * (1 - 2 * stem.droop));
	}
}

public struct StemParams {
	double droop;
	double angle;
	double len;
	double diam_start;
	double diam_end;
	uint seg_count;

	public static Orbit orbit(StemParams stem) {
		double slope_x = Math.cos(stem.angle);
		double slope_y = -Math.sin(stem.angle);
		double len = stem.len;
		double droop = stem.droop;
		return Orbit.line_with_droop(slope_x, slope_y, len, droop);
	}
}

public struct HeadParams {
	double width;
	double height;
	StipplesParams stipples;
	BractsParams bracts;
}

public struct StipplesParams {
	double spacing;
	double diam;
	double curvature;
}

public struct BractsParams {
	double base_width;
	double max_offset;
	double len;
	uint count;
	uint seg_count;
}

public struct StalkDetails {
	BractDetails[] bracts;

	public static StalkDetails generate(StalkParams stalk) {
		StalkDetails details = StalkDetails() {
			bracts = BractDetails.generate(stalk.head)
		};
		return details;
	}
}

public struct BractDetails {
	double shade;
	double x0;
	double y0;
	double x1;
	double y1;
	double x2;
	double y2;
	double x3;
	double y3;

	public static BractDetails[] generate(HeadParams head) {
		BractDetails[] details = new BractDetails[head.bracts.count];
		for (uint bract_idx = 0; bract_idx < head.bracts.count; ++bract_idx) {
			double x0 =
				(bract_idx / (head.bracts.count - 1) - 0.5)
				* (head.width - head.bracts.base_width);
			double y0 = 0;
			double x1 = x0 + 0.5 * random_sym(head.bracts.max_offset);
			double y1 = y0
				+ 0.2 * head.bracts.len * Random.double_range(0.9, 1.1);
			double x3 = x0 + random_sym(head.bracts.max_offset);
			double y3 = y0
				+ head.bracts.len * Random.double_range(0.7, 1.3);
			double x2 = x3 + 0.5 * random_sym(head.bracts.max_offset);
			double y2 = y3
				- 0.2 * head.bracts.len * Random.double_range(0.9, 1.1);
			details[bract_idx] = BractDetails() {
				shade = Random.double_range(0.7, 1),
				x0 = x0, y0 = y0,
				x1 = x1, y1 = y1,
				x2 = x2, y2 = y2,
				x3 = x3, y3 = y3
			};
		}
		return details;
	}
}

// Draws the stalk at the origin.
public void draw_stalk(
		Cairo.Context ctx,
		StalkParams stalk,
		StalkDetails stalk_details) {
	Point root_pos = StalkParams.root_pos();
	Point head_pos = StalkParams.head_pos(stalk.stem);
	double head_angle = StalkParams.head_angle(stalk.stem);

	ctx.save();
	ctx.translate(root_pos.x, root_pos.y);
	Draw.draw_stem(ctx, stalk.stem);
	ctx.restore();

	ctx.save();
	ctx.translate(head_pos.x, head_pos.y);
	ctx.rotate(head_angle);
	Draw.draw_head(ctx, stalk.head, stalk_details.bracts);
	ctx.restore();
}

// Draws the stem, assuming root transformations.
public void draw_stem(
		Cairo.Context ctx,
		StemParams stem) {
	double slope_x = Math.cos(stem.angle);
	double slope_y = -Math.sin(stem.angle);
	Point head_pos = StalkParams.head_pos(stem);
	Orbit stem_orbit = StemParams.orbit(stem);
	Orbit.OffsetParameterization offset = (t) => lerp(
		0.5 * stem.diam_start,
		0.5 * stem.diam_end, t);
	Orbit offset_stem_orbit =
		stem_orbit.offset(offset)
		.append(
			stem_orbit.offset((t) => -offset(t)).reverse());

	ctx.save();

	ctx.new_path();
	DrawUtil.orbit_to(ctx, offset_stem_orbit, stem.seg_count);
	ctx.close_path();

	// Main part of the stem.
	// TODO: Fix up the gradient start and end positions.
	ctx.save();
	double grad_start_excess = 128;
	double grad_end_excess = 128;
	Point grad_start = Point() {
		x = -grad_start_excess * slope_x,
		y = -grad_start_excess * slope_y
	};
	Point grad_end = Point() {
		x = head_pos.x + grad_end_excess * slope_x,
		y = head_pos.y + grad_end_excess * slope_y
	};
	Cairo.Pattern grad = new Cairo.Pattern.linear(
		grad_start.x, grad_start.y,
		grad_end.x, grad_end.y);
	grad.add_color_stop_rgb(0, 0.706, 0.863, 0.588);
	grad.add_color_stop_rgb(1, 0.627, 0.510, 0.451);
	ctx.set_source(grad);
	ctx.fill_preserve();
	ctx.restore();

	// Light on the one side.
	ctx.save();
	double light_grad_excess = 0.5 * stem.diam_start;
	Point light_grad_start = Point() {
		x = light_grad_excess * slope_y,
		y = -light_grad_excess * slope_x
	};
	Point light_grad_end = Point() {
		x = -light_grad_excess * slope_y,
		y = light_grad_excess * slope_x
	};
	Cairo.Pattern light_grad = new Cairo.Pattern.linear(
		light_grad_start.x, light_grad_start.y,
		light_grad_end.x, light_grad_end.y);
	light_grad.add_color_stop_rgba(0, 1, 1, 1, 0.3);
	light_grad.add_color_stop_rgba(1, 1, 1, 1, 0);
	ctx.set_operator(Cairo.Operator.ATOP);
	ctx.set_source(light_grad);
	ctx.fill_preserve();
	ctx.restore();

	// Bright outline.
	ctx.save();
	ctx.clip_preserve();
	ctx.set_source_rgba(1, 1, 1, 0.15);
	ctx.set_line_width(2);
	ctx.stroke_preserve();
	ctx.set_line_width(4);
	ctx.stroke_preserve();
	ctx.set_line_width(6);
	ctx.stroke_preserve();
	ctx.restore();

	ctx.restore();
}

// Draws the head of the stalk, assuming head transformations.
public void draw_head(
		Cairo.Context ctx,
		HeadParams head,
		BractDetails[] bract_details) {
	Draw.draw_bracts(ctx, head, bract_details);

	ctx.save();
	ctx.scale(0.5 * head.width, 0.5 * head.height);
	ctx.new_path();
	ctx.arc(0, 0, 1, 0, 2 * Math.PI);
	ctx.close_path();
	Cairo.Pattern grad = new Cairo.Pattern.linear(
		0, -0.5 * head.height,
		0, 0.5 * head.height);
	grad.add_color_stop_rgb(0, 1, 1, 0.706);
	grad.add_color_stop_rgb(0.3, 1, 1, 0.706);
	grad.add_color_stop_rgb(0.9, 0.588, 0.588, 0.392);
	grad.add_color_stop_rgb(1, 0.588, 0.588, 0.392);
	ctx.set_source(grad);
	ctx.fill();
	ctx.restore();

	Draw.draw_head_stipples(ctx, head);
}

// Draws the bracts around the head, assuming head transformations.
public void draw_bracts(
		Cairo.Context ctx,
		HeadParams head,
		BractDetails[] bract_details) {
	ctx.save();
	foreach (BractDetails bract_detail in bract_details) {
		Orbit bract_orbit = Orbit.cubic_spline(
			bract_detail.x0, bract_detail.y0,
			bract_detail.x1, bract_detail.y1,
			bract_detail.x2, bract_detail.y2,
			bract_detail.x3, bract_detail.y2);
		Orbit.OffsetParameterization offset = (t) =>
			lerp(0.5 * head.bracts.base_width, 0, t);
		Orbit offset_bract_orbit =
			bract_orbit.offset(offset)
			.append(
				bract_orbit.offset((t) => -offset(t)).reverse());

		ctx.save();
		ctx.new_path();
		DrawUtil.orbit_to(ctx, offset_bract_orbit, head.bracts.seg_count);
		ctx.close_path();
		ctx.set_source_rgb(
			0.235 * bract_detail.shade,
			0.353 * bract_detail.shade,
			0.137 * bract_detail.shade);
		ctx.fill();
		ctx.restore();
	}
	ctx.restore();
}

// Draws the stipples on the head, assuming head transformations.
public void draw_head_stipples(
		Cairo.Context ctx,
		HeadParams head) {
	uint ring_count =
		(uint) Math.ceil(head.height / head.stipples.spacing);
	for (uint ring_idx = 0; ring_idx < ring_count; ++ring_idx) {
		double color_factor = 1 - 0.45 * ((double) (ring_idx + 1) / ring_count);
		double ellipse_diam_x =
			head.width - 0.5 * head.stipples.diam;
		double ellipse_diam_y =
			head.height - 0.5 * head.stipples.diam;
		double y1 = ellipse_diam_y * ((ring_idx + 0.5) / ring_count - 0.5);
		double y2 =
			y1 + ellipse_diam_y * head.stipples.curvature / ring_count;
		double y3 = y1;
		double x1 = 0.5 * ellipse_diam_x
			* Math.sqrt(1 - square(y1 / (0.5 * ellipse_diam_y)));
		if (ring_idx % 2 == 0) {
			x1 = -x1;
		}
		double x2 = 0;
		double x3 = -x1;
		double dash_offset = (ring_idx % 2 == 0) ? 0.25 : 0.75;

		ctx.save();
		ctx.new_path();
		ctx.move_to(x1, y1);
		ctx.curve_to(
			x2, y2,
			x2, y2,
			x3, y3
		);
		ctx.set_line_width(head.stipples.diam);
		ctx.set_line_cap(Cairo.LineCap.ROUND);
		ctx.set_dash(
			new double[] { 0, head.stipples.spacing },
			dash_offset * head.stipples.spacing);
		ctx.set_source_rgb(
			1 * color_factor,
			1 * color_factor,
			0.706 * color_factor);
		ctx.stroke();
		ctx.restore();
	}
}

}

