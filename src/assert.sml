structure Assert :> ASSERT = struct
  exception Failure of string;

  fun !! is_success msg =
    if is_success then ()
    else raise Failure msg;

  fun eq expected actual msg =
    !! (expected = actual) msg;
end;

