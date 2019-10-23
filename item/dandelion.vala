namespace Dandy.Item {

using Dandy;

public class Dandelion : Item {
	public Dandelion() {
		Draw.DandelionParams params = Draw.DandelionParams.generate();
		Draw.DandelionDetails details = Draw.DandelionDetails.generate(params);
		Util.Bounds bounds = params.bounds();
		base.draw(bounds, (ctx) => {
			Draw.draw_dandelion(ctx, params, details);
		});
	}
}

}

