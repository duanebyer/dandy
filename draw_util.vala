public class Dandy.DrawUtil {

	public static void path_to(
			Cairo.Context ctx,
			Path path,
			uint seg_count) {
		double delta = 1.0 / (seg_count - 1);
		for (uint seg_idx = 0; seg_idx < seg_count; ++seg_idx) {
			double t = seg_idx * delta;
			Util.Point next_point = path.at(t);
			ctx.line_to(next_point.x, next_point.y);
		}
	}
}

