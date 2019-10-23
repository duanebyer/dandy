namespace Dandy.Draw {

using Util;

public struct DandelionParams {
	StalkParams stalk;
	AnchoredFluffsParams anchored_fluffs;

	public static DandelionParams generate() {
		return DandelionParams() {
			stalk = StalkParams.generate(),
			anchored_fluffs = AnchoredFluffsParams() {
				spacing = 25 * Math.PI / 180,
				rot_var = 0.3,
				tilt_var = 0.3
			}
		};
	}

	public Bounds bounds() {
		FluffParams fluff_params = FluffParams.generate();
		fluff_params.orient.tilt = 0.5 * Math.PI;
		Bounds fluff_bounds = fluff_params.bounds();
		double fluff_padding = Math.fmax(fluff_bounds.width(), fluff_bounds.height());
		Bounds stalk_bounds = this.stalk.bounds();
		return stalk_bounds.pad(fluff_padding);
	}

	public static Vector root_pos() {
		return Vector(0, 0);
	}
}

public struct AnchoredFluffsParams {
	double spacing;
	double rot_var;
	double tilt_var;
}

public struct DandelionDetails {
	StalkDetails stalk;
	AnchoredFluffDetails[] anchored_fluffs;

	public static DandelionDetails generate(DandelionParams dandelion) {
		return DandelionDetails() {
			stalk = StalkDetails.generate(dandelion.stalk),
			anchored_fluffs = AnchoredFluffDetails.generate(
				dandelion.stalk,
				dandelion.anchored_fluffs)
		};
	}
}

public struct AnchoredFluffDetails {
	FluffParams fluff_params;
	FluffDetails fluff_details;
	double rot;

	public static AnchoredFluffDetails[] generate(
			StalkParams stalk,
			AnchoredFluffsParams anchored_fluffs) {
		AnchoredFluffDetails[] details;
		uint rot_count = (uint) Math.ceil(Math.PI / anchored_fluffs.spacing);
		uint tilt_count = (uint) Math.ceil(Math.PI / anchored_fluffs.spacing);
		details = new AnchoredFluffDetails[rot_count * tilt_count];
		for (uint tilt_idx = 0; tilt_idx < tilt_count; ++tilt_idx) {
			for (uint rot_idx = 0; rot_idx < rot_count; ++rot_idx) {
				double rot_offset = (tilt_idx % 2 == 0 ? 0.5 : 0);
				double rot = 2 * Math.PI * (rot_idx + rot_offset
					+ Util.random_sym(anchored_fluffs.rot_var)) / rot_count;
				double tilt = 0.5 * Math.PI * (tilt_count - tilt_idx - 1
					+ Util.random_sym(anchored_fluffs.tilt_var)) / tilt_count;
				FluffParams fluff_params = FluffParams.generate();
				fluff_params.orient = OrientParams() {
					tilt = tilt,
					roll = 0
				};
				FluffDetails fluff_details = FluffDetails.generate(fluff_params);
				details[(tilt_idx * rot_count) + rot_idx] = AnchoredFluffDetails() {
					fluff_params = fluff_params,
					fluff_details = fluff_details,
					rot = rot
				};
			}
		}
		return details;
	}
}

public void draw_dandelion(
		Cairo.Context ctx,
		DandelionParams dandelion,
		DandelionDetails dandelion_details) {
	Vector root_pos = DandelionParams.root_pos();
	Vector head_pos = StalkParams.head_pos(dandelion.stalk.stem);
	double head_angle = StalkParams.head_angle(dandelion.stalk.stem);

	ctx.save();
	ctx.translate(root_pos.x, root_pos.y);
	Draw.draw_stalk(ctx, dandelion.stalk, dandelion_details.stalk);
	ctx.restore();

	ctx.save();
	ctx.translate(head_pos.x, head_pos.y);
	ctx.rotate(head_angle);
	draw_anchored_fluffs(ctx,
		dandelion.stalk,
		dandelion.anchored_fluffs,
		dandelion_details.anchored_fluffs);
	ctx.restore();
}

public void draw_anchored_fluffs(
		Cairo.Context ctx,
		StalkParams stalk,
		AnchoredFluffsParams anchored_fluffs,
		AnchoredFluffDetails[] anchored_fluff_details) {
	foreach (AnchoredFluffDetails anchored_fluff_detail in anchored_fluff_details) {
		FluffParams fluff_params = anchored_fluff_detail.fluff_params;
		FluffDetails fluff_details = anchored_fluff_detail.fluff_details;
		double rot = anchored_fluff_detail.rot;
		double tilt = fluff_params.orient.tilt;
		Vector pos = Vector.polar(0.5 * tilt / (0.5 * Math.PI), rot + 0.5 * Math.PI);
		pos.x *= stalk.head.width;
		pos.y *= stalk.head.height;
		ctx.save();
		ctx.translate(pos.x, pos.y);
		ctx.rotate(rot);
		Draw.draw_fluff(ctx, fluff_params, fluff_details);
		ctx.restore();
	}
}

}

