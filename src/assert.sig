signature ASSERT = sig
  exception Failure of string;

  val !! : bool -> string -> unit;
  val eq : ''a -> ''a -> string -> unit;
end;

