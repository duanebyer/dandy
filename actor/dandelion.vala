namespace Dandy.Actor {

using Dandy;

public class Dandelion : Item {
	public Dandelion(
			Util.Camera camera,
			double len,
			double resolution_factor = 1) {
		base(camera);
		Draw.DandelionParams params = Draw.DandelionParams.generate();
		params.stalk.stem.len = len;
		Draw.DandelionDetails details = Draw.DandelionDetails.generate(params);
		Util.Bounds bounds = params.bounds();
		base.update_base_image(bounds, resolution_factor, (ctx) => {
			Draw.draw_dandelion(ctx, params, details);
		});
	}
}

}

