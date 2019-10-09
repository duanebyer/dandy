// An actor for rendering a small piece of dandelion fluff.
public class Dandy.Fluff : Clutter.Actor {

	private static const uint _PITCH_COUNT = 10;
	private static const uint _FLUFF_COUNT = 10;
	// The resolution of the canvas relative to the default size of the fluff
	// when rendering at a scaling of 1. If there is a chance that the canvas
	private static const float _SCALE_FACTOR = 2;
	// A series of canvases, each one drawing the fluff at a different pitch.
	private static Clutter.Canvas[,] _canvases;
	
	// Controls the angle of the fluff in the third dimension.
	public float pitch { get; set; }

	construct {
	}

	static construct {
		Fluff._canvases = new Clutter.Canvas[Fluff._FLUFF_COUNT, Fluff._PITCH_COUNT];
		// Create a sequence of dandelion fluffs, each drawn at a number of
		// different pitches.
		for (uint fluff_idx = 0; fluff_idx < Fluff._FLUFF_COUNT; ++fluff_idx) {
			// Generate constants here so that they will be the same through all
			// tilts.

			// Dandelion fluffs have a seed, connected by a strand to an anchor,
			// which then separates into many strands travelling outward from
			// the anchor.

			// The seed itself is an ellipse stretched in one dimension.
			float seed_radius = 2;
			float seed_length = 5;
			float fluff_anchor_offset = 48;
			float fluff_anchor_
			for (uint pitch_idx = 0; pitch_idx < Fluff._PITCH_COUNT; ++pitch_idx) {
				
			}
		}
	}
}

