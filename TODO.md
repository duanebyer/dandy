# TODO list
## Features
* Draw the hill underneath the grass.
* Draw dandelions at different phases in life cycle.
* Add interactive dandelions.
* Add a fluid simulation.
## Performance
* There should be error checking on graphics methods used in DrawUtil and Item.
* Increase performance of drawing to items. One possibility is to use a
  different type of Cairo surface.
* Increase the performance of applying a blur effect. Can it be done on the GPU?
* Consider making the blur effect a proper Clutter.Effect. Problem is that we
  don't want to update the blur everytime the actor moves.
* Look into `clutter_actor_set_offscreen_redirect` and
  `clutter_actor_has_overlaps` as ways of possibly improving performance.
## Bugs
* When a Clutter canvas is invalidated, the new contents are undefined. Make
  sure to always clear the canvas using a Cairo paint (with the appropriate
  operator) before rendering to a canvas.
## Simulation
* Make advection flow forwards in time, despite numerical instability. Try to
  find a way to keep it stable even while doing this.
* Switch from rectangular grids to square grids.
* Mouse velocity impulse should be over a gaussian region, not at a point.
* Add some kind of drag term to the field (that gradually brings the field back
  to zero if left alone).
## Code quality
* Use `nx` and `ny` variables instead of using `.length[0]` all over the place.
* Add sealed modifier to most classes.
* Make many classes compact.
* Explicit access modifiers on every field.
* Consider replacing asserts with contracts (require clause).
* Determine if there should be bound checks in field (probably yes).
* Be more consistent about where properties and where getters are used.
* Add run-time check on Bounds creation to make sure that it is a non-negative
  sized region.
* Order elements of classes/namespaces in more consistent ways.
* Consistency when calling internal methods (this.method() or method()).
* Determine when a class should extend Object and when it shouldn't.
* Come up with a nicer way to generate the items in the stage. Perhaps the
  generation code can be moved out to another class.
* Add more comments, particularly describing how the images of different items
  are made.
* Fix bugs where a closure tries to own something in its environment. Does this
  even work?
* Every param should have its own generate method. Also details classes should
  be more consistent about how they are generated.
* Go through colours and make better choices (how many digits?).
* Be consistent about when namespaces are used (one namespace level should
  always be used, unless we are in the same namespace).
* Move shade parameters to a better spot within the parameter structs.
* Rename Orbit and OffsetParameterization.
* Better constructors. Throw errors when invalid parameters are given, and
  consider when/where to use construct blocks.
* Better error handling and asserts throughout everything.
* Make everything internal at the end except for the simulation class.
* Make sure that ownership is correct everywhere.
* Remove all warnings
* Just use ints for all indices, not uints. If something must be positive, just
  add a runtime check.
## Testing
* Make sure that the field classes are being passed compatible fields (so that
  new fields aren't being created every timestep).
* Check the sinc and cosc functions near x=0.
* Make sure that resizing the background properly recreates the scene.
