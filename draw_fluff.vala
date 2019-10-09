public class Dandy.DrawFluff {

	// A fluff has three main parts: a seed, an anchor, and a collection of
	// strands connected to the anchor.
	public struct Params {
		OrientParams orient;
		SeedParams seed;
		AnchorParams anchor;
		StrandsParams strands;
	}

	public struct OrientParams {
		double tilt; // The tilt in the third dimension (fore-shortened).
		double roll; // The roll.
	}

	public struct SeedParams {
		double diam; // The shape of the ellipsoidal seed.
		double len;
	}

	public struct AnchorParams {
		double offset; // Distance from anchor to seed.
		double diam; // The diameter of the spherical anchor.
	}

	public struct StrandsParams {
		double ellipse_width; // The shape of the volume that the strands occupy.
		double ellipse_height;
		double len_var; // Percentage variation in lengths of strands.
		double ellipse_offset; // Distance from anchor to ellipse center.
		double base_diam; // Size of strand near the anchor.
		double curvature_var; // Variance in amount of curvature of a strand.
		uint count; // How many strands are there?
	}

	public struct Details {
		StrandDetails[] strands;
	}

	public struct StrandDetails {
		double x; // Coordinates of the end of the strand.
		double y;
		double z;
		double curvature; // Amount of deviation of center from straight line.
	}
	
	// Creates parameters from a random distribution. Sometimes, populations of
	// objects can have different parameters from one another.
	public static Params gen_params() {
		return Params() {
			orient = OrientParams() {
				tilt = Random.double_range(0, 0.5 * Math.PI),
				roll = Random.double_range(0, 2 * Math.PI)
			},
			seed = SeedParams() {
				diam = 5,
				len = 12
			},
			anchor = AnchorParams() {
				offset = 48,
				diam = 2
			},
			strands = StrandsParams() {
				ellipse_width = 80,
				ellipse_height = 40,
				len_var = 0.25,
				ellipse_offset = 8,
				base_diam = 2,
				curvature_var = 8,
				count = 50
			}
		};
	}

	// Generates the specific details of an object from a set of parameters,
	// such as the shapes of individual blades of grass.
	public static Details gen_details(Params params) {
		Details details = Details() {
			strands = new StrandDetails[params.strands.count]
		};
		for (uint strand_idx = 0; strand_idx < params.strands.count; ++strand_idx) {
			// The phi component is chosen within the narrow wedge of the full
			// circle to evenly space the strands around.
			double phi_spacing = 2 * Math.PI / params.strands.count;
			double phi = phi_spacing * strand_idx
				+ Random.double_range(0, phi_spacing);
			double theta = Math.acos(Util.random_sym(1));
			double s = 1 + Util.random_sym(params.strands.len_var);
			double sx = 0.5 * s * params.strands.ellipse_width;
			double sz = 0.5 * s * params.strands.ellipse_height;
			double x = sx * Math.cos(phi) * Math.cos(theta);
			double y = sx * Math.sin(phi) * Math.cos(theta);
			double z = sz * Math.sin(theta);
			details.strands[strand_idx] = StrandDetails() {
				x = x, y = y, z = z,
				curvature = Util.random_sym(params.strands.curvature_var)
			};
		}
		return details;
	}

	// Returns a guaranteed bound on the size of the image generated using the
	// specified parameters.
	public static Util.Bounds get_bounds(Params params) {
		params.orient.tilt = Util.bound_angle(params.orient.tilt);
		double padding = 4;
		double x1 =
			-0.5 * params.strands.ellipse_width * (1 + params.strands.len_var)
			- padding;
		double x2 = -x1;
		double y1 =
			0.5 * params.strands.ellipse_width * (1 + params.strands.len_var)
			+ padding;
		double y2 = -y1;
		double y_offset = (params.anchor.offset + params.strands.ellipse_offset)
			* Math.sin(params.orient.tilt);
		if (params.orient.tilt > 0) {
			y1 += y_offset;
		} else {
			y2 += y_offset;
		}
		return Util.Bounds() {
			x1 = x1, y1 = y1, x2 = x2, y2 = y2
		};
	}

	public static Util.Point get_seed_pos() {
		return Util.Point() { x = 0, y = 0 };
	}

	public static Util.Point get_anchor_pos(
			OrientParams orient,
			AnchorParams anchor) {
		double anchor_y = anchor.offset * Math.sin(orient.tilt);
		return Util.Point() { x = 0, y = anchor_y };
	}

	// Render the object using the provided parameters and details. This step is
	// always deterministic.
	public static void draw(
			Cairo.Context ctx,
			Params params,
			Details details) {
		params.orient.tilt = Util.bound_angle(params.orient.tilt);

		// The order to draw depends on the tilt. Either: seed, stalk, strands,
		// anchor; or, strands, anchor, stalk, seed.
		Util.Point seed_pos = DrawFluff.get_seed_pos();
		Util.Point anchor_pos = DrawFluff.get_anchor_pos(params.orient, params.anchor);
		if (params.orient.tilt > -0.5 * Math.PI
				&& params.orient.tilt < 0.5 * Math.PI) {
			ctx.save();
			ctx.translate(seed_pos.x, seed_pos.y);
			DrawFluff.draw_seed(ctx, params.orient, params.seed);
			DrawFluff.draw_anchor_line(ctx,
				params.orient,
				params.seed,
				params.anchor);
			ctx.restore();
			ctx.save();
			ctx.translate(anchor_pos.x, anchor_pos.y);
			DrawFluff.draw_strands(ctx,
				params.orient,
				params.strands,
				details.strands);
			DrawFluff.draw_anchor(ctx, params.anchor);
			ctx.restore();
		} else {
			ctx.save();
			ctx.translate(anchor_pos.x, anchor_pos.y);
			DrawFluff.draw_strands(ctx,
				params.orient,
				params.strands,
				details.strands);
			DrawFluff.draw_anchor(ctx, params.anchor);
			ctx.restore();
			ctx.save();
			ctx.translate(seed_pos.x, seed_pos.y);
			DrawFluff.draw_anchor_line(ctx,
				params.orient,
				params.seed,
				params.anchor);
			DrawFluff.draw_seed(ctx, params.orient, params.seed);
			ctx.restore();
		}
	}

	// Draws the seed, assuming seed transformations.
	private static void draw_seed(
			Cairo.Context ctx,
			OrientParams orient,
			SeedParams seed) {
		ctx.save();
		ctx.new_path();
		ctx.scale(
			0.5 * seed.diam,
			0.5 * seed.len * Util.lerp(
				Math.fabs(Math.sin(orient.tilt)), 1,
				seed.diam / seed.len));
		ctx.arc(0, 0, 1, 0, 2 * Math.PI);
		ctx.close_path();
		ctx.set_source_rgb(0.314, 0.0784, 0);
		ctx.fill();
		ctx.restore();
	}

	// Draws the anchor line, assuming seed transformations.
	private static void draw_anchor_line(
			Cairo.Context ctx,
			OrientParams orient,
			SeedParams seed,
			AnchorParams anchor) {
		Util.Point seed_pos = DrawFluff.get_seed_pos();
		Util.Point anchor_pos = DrawFluff.get_anchor_pos(orient, anchor);
		double connection_y = 0.5 * seed.len * Math.sin(orient.tilt);
		ctx.save();
		ctx.new_path();
		ctx.move_to(0, connection_y);
		ctx.line_to(anchor_pos.x - seed_pos.x, anchor_pos.y - seed_pos.y);
		ctx.set_line_width(1);
		ctx.set_line_cap(Cairo.LineCap.ROUND);
		ctx.set_source_rgb(1, 1, 1);
		ctx.stroke();
		ctx.restore();
	}

	// Draws the anchor itself, assuming anchor transformations.
	private static void draw_anchor(
			Cairo.Context ctx,
			AnchorParams anchor) {
		ctx.save();
		ctx.new_path();
		ctx.arc(0, 0, 0.5 * anchor.diam, 0, 2 * Math.PI);
		ctx.close_path();
		ctx.set_source_rgb(0.706, 0.667, 0.627);
		ctx.fill();
		ctx.restore();
	}

	// Draws the strands, assuming anchor transformations.
	private static void draw_strands(
			Cairo.Context ctx,
			OrientParams orient,
			StrandsParams strands,
			StrandDetails[] strand_details) {
		ctx.save();
		ctx.set_source_rgba(1, 1, 1, 0.2);
		foreach (StrandDetails strand_detail in strand_details) {
			double x =
				strand_detail.x * Math.cos(orient.roll) +
				strand_detail.y * Math.sin(orient.roll);
			double y =
				(strand_detail.z + strands.ellipse_offset) * Math.sin(orient.tilt) +
				Math.cos(orient.tilt) * (
					-strand_detail.x * Math.sin(orient.roll) +
					strand_detail.y * Math.cos(orient.roll));
			double len = Util.length(x, y);

			double base_delta_x = 0.5 * strands.base_diam * y / len;
			double base_delta_y = -0.5 * strands.base_diam * x / len;

			double curve = strand_detail.curvature;
			double curve_x = 0.5 * x + curve * y / len;
			double curve_y = 0.5 * y - curve * x / len;

			ctx.new_path();
			ctx.move_to(base_delta_x, base_delta_y);
			ctx.curve_to(
				curve_x + 0.5 * base_delta_x, curve_y + 0.5 * base_delta_y,
				curve_x + 0.5 * base_delta_x, curve_y + 0.5 * base_delta_y,
				x, y);
			ctx.curve_to(
				curve_x - 0.5 * base_delta_x, curve_y - 0.5 * base_delta_y,
				curve_x - 0.5 * base_delta_x, curve_y - 0.5 * base_delta_y,
				-base_delta_x, -base_delta_y);
			ctx.close_path();
			ctx.fill();
		}
		ctx.restore();
	}
}

