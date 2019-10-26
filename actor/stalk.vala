namespace Dandy.Actor {

using Dandy;

public class Stalk : Item {
	public Stalk(Util.Camera camera, double resolution_factor = 1) {
		base(camera);
		Draw.StalkParams params = Draw.StalkParams.generate();
		Draw.StalkDetails details = Draw.StalkDetails.generate(params);
		Util.Bounds bounds = params.bounds();
		base.update_base_image(bounds, resolution_factor, (ctx) => {
			Draw.draw_stalk(ctx, params, details);
		});
	}
}

}

