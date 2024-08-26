structure TestResult :> TEST_RESULT = struct
  datatype Outcome = Success
                   | Failure of string
                   | Error of exn;
  
  datatype t = Case of string * Time.time * Outcome
             | Suite of string * Time.time * (t list);

(* *** smart constructors *** *)
  
  fun for_case name assertion =
    let
      val start = Time.now();
    in
      (assertion();
       Case(name,
            (Time.-)(Time.now(), start),
            Success))
      handle Assert.Failure msg =>
             Case (name,
                   (Time.-)(Time.now(), start),
                   Failure msg)
             | e => Case(name,
                         (Time.-)(Time.now(), start),
                         Error e)
    end;

  fun for_suite name form_results =
    let
      val start = Time.now();
      val results = form_results ();
      val dt = (Time.-)(Time.now(), start);
    in
      Suite (name, dt, results)
    end;

(* *** accessor functions *** *)
  
  fun name (Case (n,_,_)) = n
    | name (Suite (n,_,_)) = n;

  (* runtime : t -> Time.time

How long did it take to run the test(s) and construct the
result(s)? *)
  fun runtime (Case (_,dt,_)) = dt
    | runtime (Suite (_,dt,_)) = dt;

  (* realtime : t -> Time.time

How long did it take just to run the test(s)? *)
  fun realtime (Case (_,dt,_)) = dt
    | realtime (Suite (_,_,[])) = Time.zeroTime
    | realtime (Suite (_,_,[x])) = realtime x
    | realtime (Suite (_,_,r::rs)) =
      foldl (fn (result,dt) =>
                (Time.+)(dt, realtime result))
            (realtime r)
            rs;
  
  fun count_successes (Case (_,_,Success)) = 1
    | count_successes (Case _) = 0 
    | count_successes (Suite (_,_,outcomes)) =
      foldl (op +) 0 (map count_successes outcomes);

  fun count_failures (Case (_,_,Failure _)) = 1
    | count_failures (Case _) = 0
    | count_failures (Suite (_,_,outcomes)) =
      foldl (op +) 0 (map count_failures outcomes);

  fun count_errors (Case (_,_,Error _)) = 1
    | count_errors (Case _) = 0
    | count_errors (Suite (_,_,outcomes)) =
      foldl (op +) 0 (map count_errors outcomes);

  fun count_total x =
    count_successes x + count_failures x + count_errors x;

  fun is_success x = (count_total x) = (count_successes x);

  fun is_failure (Case (_,_, Failure _)) = true
    | is_failure (Case _) = false
    | is_failure (s as Suite _) =
      (count_failures s) > 0;

  fun is_error (Case (_,_, Error _)) = true
    | is_error (Case _) = false
    | is_error (s as Suite _) =
      (count_errors s) > 0;

  fun interval_to_string (dt : Time.time) =
    (LargeInt.toString (Time.toMicroseconds dt))^"ms";

  fun report case_report suite_report =
    fn (c as Case _) => case_report c
    | (s as Suite (_,_,results)) =>
      suite_report s results;

  fun msg (Case (_,_,Failure msg)) = msg
    | msg _ = "";

  fun exn_message (Case (_,_,Error e)) = exnMessage e
    | exn_message _ = ""; 

end;
