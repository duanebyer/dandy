namespace Dandy.Item {

using Dandy;

public class Stalk : Item {
	public Stalk() {
		Draw.StalkParams params = Draw.StalkParams.generate();
		Draw.StalkDetails details = Draw.StalkDetails.generate(params);
		Util.Bounds bounds = params.bounds();
		base.draw(bounds, (ctx) => {
			Draw.draw_stalk(ctx, params, details);
		});
	}
}

}

