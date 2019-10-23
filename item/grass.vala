namespace Dandy.Item {

using Dandy;

public class Grass : Item {
	public Grass(double length_x, double length_y, double scale = 1) {
		// Create a small clump of grass in a hexagon of a certain radius.
		double spacing = 16;
		uint grass_x_count = (uint) Math.ceil(length_x / spacing);
		uint grass_y_count = (uint) Math.ceil(length_y / spacing);
		Util.Bounds bounds = Util.Bounds(0, 0, 0, 0);
		Gee.ArrayList<Draw.GrassParams?> params_list =
			new Gee.ArrayList<Draw.GrassParams?>();
		Gee.ArrayList<Util.Vector?> pos_list =
			new Gee.ArrayList<Util.Vector?>();
		for (uint y_idx = 0; y_idx < grass_y_count; ++y_idx) {
			for (int x_idx = 0; x_idx < grass_x_count; ++x_idx) {
				Util.Vector pos = Util.Vector(
					((x_idx + Random.next_double()) / grass_x_count - 0.5) * length_x,
					((y_idx + Random.next_double()) / grass_y_count - 1) * length_y);
				Draw.GrassParams params = Draw.GrassParams.generate();
				bounds = bounds.union(params.bounds().add(pos));
				params_list.add(params);
				pos_list.add(pos);
			}
		}
		pos_list.sort((a, b) => Util.compare(a.y, b.y));
		base.draw(bounds, scale, (ctx) => {
			for (int idx = 0; idx < params_list.size; ++idx) {
				Draw.GrassParams params = params_list[idx];
				Util.Vector pos = pos_list[idx];
				Draw.GrassDetails details = Draw.GrassDetails.generate(params);
				ctx.save();
				ctx.translate(pos.x, pos.y);
				Draw.draw_grass(ctx, params, details);
				ctx.restore();
			}
		});
	}
}

}

