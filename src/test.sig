signature TEST = sig
  type Test;
  type t = Test;
  structure Result : TEST_RESULT;

  val suite : string -> Test list -> Test;
  val new : string -> (unit -> unit) -> Test;
  val register_suite : string -> Test list -> Test;
  val run : Test -> Result.t;
  val run_all : unit -> Result.t list;
  val path : string -> string -> string;
  val exit_status : Result.t list -> OS.Process.status;
end;

