(*
The REPORTER formats and writes the results...somewhere.
This could be to the screen (usually done by reporters
suffixed by `_Tt`) or to a file.

Either way, this is a `unit` return type.

The reason for `report_all` as separate than `report` is
because `report` could create a new file each time it is
called (which might be undesirable if we want to write all the
results to a single file).
*)
signature REPORTER = sig
  val report : Test.Result.t -> unit;
  val report_all : Test.Result.t list -> unit;
end;
