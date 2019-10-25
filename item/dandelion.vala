namespace Dandy.Item {

using Dandy;

public class Dandelion : Item {
	public Dandelion(double len, double scale = 1) {
		Draw.DandelionParams params = Draw.DandelionParams.generate();
		params.stalk.stem.len = len;
		Draw.DandelionDetails details = Draw.DandelionDetails.generate(params);
		Util.Bounds bounds = params.bounds();
		base.draw(bounds, scale, (ctx) => {
			Draw.draw_dandelion(ctx, params, details);
		});
	}
}

}

