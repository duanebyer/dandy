namespace Dandy.Item {

using Dandy;

public class Stalk : Item {
	private Draw.StalkParams _params;
	private Draw.StalkDetails _details;

	public Stalk() {
		Draw.StalkParams params = Draw.StalkParams.generate();
		Draw.StalkDetails details = Draw.StalkDetails.generate(params);
		Util.Bounds bounds = params.bounds();
		base(bounds, (ctx) => {
			Draw.draw_stalk(ctx, params, details);
		});
		this._params = params;
		this._details = details;
	}
}

}

