namespace Dandy.Item {

using Dandy;

public class Stalk : Item {
	public Stalk(double scale = 1) {
		Draw.StalkParams params = Draw.StalkParams.generate();
		Draw.StalkDetails details = Draw.StalkDetails.generate(params);
		Util.Bounds bounds = params.bounds();
		base.draw(bounds, scale, (ctx) => {
			Draw.draw_stalk(ctx, params, details);
		});
	}
}

}

