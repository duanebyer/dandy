namespace Dandy.Draw {

using Util;

// A fluff has three main parts: a seed, an anchor, and a collection of
// strands connected to the anchor.
public struct FluffParams {
	OrientParams orient;
	SeedParams seed;
	AnchorParams anchor;
	StrandsParams strands;

	// Creates parameters from a random distribution. Sometimes, populations of
	// objects can have different parameters from one another.
	public static FluffParams generate() {
		return FluffParams() {
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

	// Returns a guaranteed bound on the size of the image generated using the
	// specified parameters.
	public Bounds bounds() {
		this.orient.tilt = bound_angle(this.orient.tilt);
		double padding = 4;
		double x1 =
			-0.5 * this.strands.ellipse_width * (1 + this.strands.len_var)
			- padding;
		double x2 = -x1;
		double y1 =
			-0.5 * this.strands.ellipse_width * (1 + this.strands.len_var)
			- padding;
		double y2 = -y1;
		double y_offset = (this.anchor.offset + this.strands.ellipse_offset)
			* Math.sin(this.orient.tilt);
		if (this.orient.tilt < 0) {
			y1 += y_offset;
		} else {
			y2 += y_offset;
		}
		return Bounds(x1, y1, x2, y2);
	}

	public static Vector seed_pos() {
		return Vector(0, 0);
	}

	public static Vector anchor_pos(
			OrientParams orient,
			AnchorParams anchor) {
		double anchor_y = anchor.offset * Math.sin(orient.tilt);
		return Vector(0, anchor_y);
	}
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

public struct FluffDetails {
	StrandDetails[] strands;

	// Generates the specific details of an object from a set of parameters,
	// such as the shapes of individual blades of grass.
	public static FluffDetails generate(FluffParams fluff) {
		FluffDetails details = FluffDetails() {
			strands = StrandDetails.generate(fluff.strands)
		};
		return details;
	}
}

public struct StrandDetails {
	Vector3 pos; // Coordinates of the end of the strand.
	double curvature; // Amount of deviation of center from straight line.

	public static StrandDetails[] generate(StrandsParams strands) {
		StrandDetails[] details = new StrandDetails[strands.count];
		for (uint strand_idx = 0; strand_idx < strands.count; ++strand_idx) {
			// The phi component is chosen within the narrow wedge of the full
			// circle to evenly space the strands around.
			double phi_spacing = 2 * Math.PI / strands.count;
			double phi = phi_spacing * strand_idx
				+ Random.double_range(0, phi_spacing);
			double theta = Math.acos(random_sym(1));
			double s = 1 + random_sym(strands.len_var);
			double sx = 0.5 * s * strands.ellipse_width;
			double sz = 0.5 * s * strands.ellipse_height;
			double x = sx * Math.cos(phi) * Math.cos(theta);
			double y = sx * Math.sin(phi) * Math.cos(theta);
			double z = sz * Math.sin(theta);
			details[strand_idx] = StrandDetails() {
				pos = Vector3(x, y, z),
				curvature = random_sym(strands.curvature_var)
			};
		}
		return details;
	}
}

// Draw the fluff at the origin.
public void draw_fluff(
		Cairo.Context ctx,
		FluffParams fluff,
		FluffDetails fluff_details) {
	fluff.orient.tilt = bound_angle(fluff.orient.tilt);

	// The order to draw depends on the tilt. Either: seed, stalk, strands,
	// anchor; or, strands, anchor, stalk, seed.
	Vector seed_pos = FluffParams.seed_pos();
	Vector anchor_pos = FluffParams.anchor_pos(fluff.orient, fluff.anchor);
	if (fluff.orient.tilt > -0.5 * Math.PI
			&& fluff.orient.tilt < 0.5 * Math.PI) {
		ctx.save();
		ctx.translate(seed_pos.x, seed_pos.y);
		Draw.draw_seed(ctx, fluff.orient, fluff.seed);
		Draw.draw_anchor_line(ctx,
			fluff.orient,
			fluff.seed,
			fluff.anchor);
		ctx.restore();
		ctx.save();
		ctx.translate(anchor_pos.x, anchor_pos.y);
		Draw.draw_strands(ctx,
			fluff.orient,
			fluff.strands,
			fluff_details.strands);
		Draw.draw_anchor(ctx, fluff.anchor);
		ctx.restore();
	} else {
		ctx.save();
		ctx.translate(anchor_pos.x, anchor_pos.y);
		Draw.draw_strands(ctx,
			fluff.orient,
			fluff.strands,
			fluff_details.strands);
		Draw.draw_anchor(ctx, fluff.anchor);
		ctx.restore();
		ctx.save();
		ctx.translate(seed_pos.x, seed_pos.y);
		Draw.draw_anchor_line(ctx,
			fluff.orient,
			fluff.seed,
			fluff.anchor);
		Draw.draw_seed(ctx, fluff.orient, fluff.seed);
		ctx.restore();
	}
}

// Draws the seed, assuming seed transformations.
private void draw_seed(
		Cairo.Context ctx,
		OrientParams orient,
		SeedParams seed) {
	ctx.save();
	ctx.new_path();
	ctx.scale(
		0.5 * seed.diam,
		0.5 * seed.len * lerp(
			Math.fabs(Math.sin(orient.tilt)), 1,
			seed.diam / seed.len));
	ctx.arc(0, 0, 1, 0, 2 * Math.PI);
	ctx.close_path();
	ctx.set_source_rgb(0.314, 0.0784, 0);
	ctx.fill();
	ctx.restore();
}

// Draws the anchor line, assuming seed transformations.
private void draw_anchor_line(
		Cairo.Context ctx,
		OrientParams orient,
		SeedParams seed,
		AnchorParams anchor) {
	Vector seed_pos = FluffParams.seed_pos();
	Vector anchor_pos = FluffParams.anchor_pos(orient, anchor);
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
private void draw_anchor(
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
private void draw_strands(
		Cairo.Context ctx,
		OrientParams orient,
		StrandsParams strands,
		StrandDetails[] strand_details) {
	ctx.save();
	ctx.set_source_rgba(1, 1, 1, 0.2);
	foreach (StrandDetails strand_detail in strand_details) {
		Vector strand_pos = strand_detail.pos
			.add(Vector3.UNIT_Z.scale(strands.ellipse_offset))
			.rotate(Vector3.UNIT_Z.scale(orient.roll))
			.rotate(Vector3.UNIT_X.scale(orient.tilt))
			.as_vector();

		Vector base_delta = strand_pos.perp().unit()
			.scale(-0.5 * strands.base_diam);
		Vector curve = strand_pos.scale(0.5)
			.add(strand_pos.perp().unit().scale(-strand_detail.curvature));

		ctx.new_path();
		ctx.move_to(base_delta.x, base_delta.y);
		ctx.curve_to(
			curve.x + 0.5 * base_delta.x, curve.y + 0.5 * base_delta.y,
			curve.x + 0.5 * base_delta.x, curve.y + 0.5 * base_delta.y,
			strand_pos.x, strand_pos.y);
		ctx.curve_to(
			curve.x - 0.5 * base_delta.x, curve.y - 0.5 * base_delta.y,
			curve.x - 0.5 * base_delta.x, curve.y - 0.5 * base_delta.y,
			-base_delta.x, -base_delta.y);
		ctx.close_path();
		ctx.fill();
	}
	ctx.restore();
}

}

