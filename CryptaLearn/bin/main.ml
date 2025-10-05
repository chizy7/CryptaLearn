(* CryptaLearn Main Executable *)

open Cryptalearn

(* === Command Line Arguments Processing === *)
let parse_args () =
  let config = ref default_config in
  let specs = [
    ("--fl-samples", Arg.Int (fun n -> config := { !config with fl_samples = n }), "Number of FL training samples");
    ("--key-size", Arg.Int (fun n -> config := { !config with key_size = n }), "Encryption key size in bits");
    ("--matrix-size", Arg.Int (fun n -> config := { !config with matrix_size = n }), "Size of test matrices");
    ("--dp-epsilon", Arg.Float (fun e -> config := { !config with dp_epsilon = e }), "DP epsilon parameter");
    ("--dp-delta", Arg.Float (fun d -> config := { !config with dp_delta = d }), "DP delta parameter");
    ("--skip-fl", Arg.Unit (fun () -> config := { !config with run_fl = false }), "Skip federated learning tests");
    ("--skip-he", Arg.Unit (fun () -> config := { !config with run_he = false }), "Skip homomorphic encryption tests");
    ("--skip-dp", Arg.Unit (fun () -> config := { !config with run_dp = false }), "Skip differential privacy tests");
    ("--no-verify", Arg.Unit (fun () -> config := { !config with verification = false }), "Disable result verification");
    ("--seed", Arg.Int (fun s -> config := { !config with seed = Some s }), "Random seed for reproducible tests");
    ("--fail-fast", Arg.Unit (fun () -> config := { !config with fail_on_error = true }), "Abort on first test error");
  ] in
  let usage = "Usage: " ^ Sys.argv.(0) ^ " [OPTIONS]" in
  Arg.parse specs (fun _ -> ()) usage;
  !config

(* === Main Entry Point === *)
let () =
  Random.self_init ();
  let config = parse_args () in
  let success = run_tests config in
  if not success && config.fail_on_error then
    exit 1
