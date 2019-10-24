# TODO list
## Features
* Draw the hill underneath the grass.
* Draw dandelions at different phases in life cycle.
* Add interactive dandelions.
* Add a fluid simulation.
## Performance
* Increase performance of drawing to items. One possibility is to use a
  different type of Cairo surface.
* Increase the performance of applying a blur effect. Can it be done on the GPU?
* Consider making the blur effect a proper Clutter.Effect. Problem is that we
  don't want to update the blur everytime the actor moves.
* Look into `clutter_actor_set_offscreen_redirect` and
  `clutter_actor_has_overlaps` as ways of possibly improving performance.
## Code quality
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
* Check the sinc and cosc functions near x=0.
