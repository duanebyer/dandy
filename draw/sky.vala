namespace Dandy.Draw {

using Util;

internal struct SkyParams {
	double width;
	double height;
	CloudsParams clouds;

	public static SkyParams generate(double width, double height) {
		return SkyParams() {
			width = width,
			height = height,
			clouds = CloudsParams() {
				count = 1000,
				height = 0.3 * height,
				diam = 96,
				diam_var = 0.4
			}
		};
	}

	public Bounds bounds() {
		return Bounds(0, 0, this.width, this.height);
	}

	public static Vector origin() {
		return Vector(0, 0);
	}
}

internal struct CloudsParams {
	uint count;
	double height;
	double diam;
	double diam_var;
}

internal struct SkyDetails {
	CloudDetails[] clouds;

	public static SkyDetails generate(SkyParams sky) {
		return SkyDetails() {
			clouds = CloudDetails.generate(sky)
		};
	}
}

internal struct CloudDetails {
	Vector pos;
	double diam;

	public static CloudDetails[] generate(SkyParams sky) {
		CloudDetails[] details = new CloudDetails[sky.clouds.count];
		for (uint cloud_idx = 0; cloud_idx < sky.clouds.count; ++cloud_idx) {
			double x = Random.double_range(0, sky.width);
			double y = -Math.log(Random.double_range(0.001, 1))
				* (sky.clouds.height + 0.5 * sky.clouds.diam)
				- 0.5 * sky.clouds.diam;
			double y_clamp = y.clamp(0, double.INFINITY);
			double diam = sky.clouds.diam * Math.exp(-y_clamp / sky.clouds.height)
				* (1 + random_sym(sky.clouds.diam_var));
			details[cloud_idx] = CloudDetails() {
				pos = Vector(x, y),
				diam = diam
			};
		}
		return details;
	}
}

internal void draw_sky(
		Cairo.Context ctx,
		SkyParams sky,
		SkyDetails details) {
	ctx.save();
	ctx.new_path();
	ctx.rectangle(0, 0, sky.width, sky.height);
	ctx.clip();
	ctx.set_source_rgb(0.667, 0.784, 0.863);
	ctx.paint();
	Draw.draw_clouds(ctx, sky.clouds, details.clouds);
	ctx.restore();
}

internal void draw_clouds(
		Cairo.Context ctx,
		CloudsParams clouds,
		CloudDetails[] cloud_details) {
	ctx.save();
	ctx.set_operator(Cairo.Operator.SCREEN);
	foreach (CloudDetails cloud_detail in cloud_details) {
		ctx.new_path();
		ctx.arc(
			cloud_detail.pos.x,
			cloud_detail.pos.y,
			0.5 * cloud_detail.diam,
			0, 2 * Math.PI);
		ctx.close_path();
		ctx.set_source_rgba(1, 0.235, 0, 0.4);
		ctx.fill();
	}
	ctx.restore();
}

}

