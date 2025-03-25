structure Assert :> ASSERT = struct
  exception Failure of string;

  fun !! is_success fail_msg =
    if is_success then ()
    else raise Failure fail_msg;

  fun eq expected actual fail_msg =
    !! (expected = actual) fail_msg;
end;

