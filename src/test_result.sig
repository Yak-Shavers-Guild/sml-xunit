(*
TODO: capture everything printed to stdout and stderr, then
allow the user access to these strings.
*)
signature TEST_RESULT = sig
  type t;
  val for_case : string -> (unit -> unit) -> t;
  val for_suite : string -> (unit -> (t list)) -> t;

  val report : (t -> string) -> (t -> t list -> string) -> t -> string;

  val name : t -> string;
  val msg : t -> string;
  val exn_message : t -> string;
  (* realtime excludes the time it took a TestSuite to
   allocate infrastructure in memory. *)
  val realtime : t -> Time.time;
  val runtime : t -> Time.time;
  
  val is_success : t -> bool;
  val is_failure : t -> bool;
  val is_error : t -> bool;

  val count_successes : t -> int;
  val count_failures : t -> int;
  val count_errors : t -> int;
  val count_total : t -> int;
end;

