open Fl
open He
open Dp

(* === Configuration === *)
type test_config = {
  fl_samples: int;          (* Number of samples for FL training *)
  key_size: int;           (* Bit size for encryption keys *)
  matrix_size: int;        (* Size of test matrices *)
  dp_epsilon: float;       (* Privacy budget *)
  dp_delta: float;        (* Privacy failure probability *)
  run_fl: bool;           (* Whether to run FL tests *)
  run_he: bool;           (* Whether to run HE tests *)
  run_dp: bool;           (* Whether to run DP tests *)
}

let default_config = {
  fl_samples = 100;
  key_size = 1024;
  matrix_size = 2;
  dp_epsilon = 0.1;
  dp_delta = 1e-5;
  run_fl = true;
  run_he = true;
  run_dp = true;
}

(* === Timing Utilities === *)
let time_operation name f =
  let start_time = Unix.gettimeofday () in
  let result = f () in
  let end_time = Unix.gettimeofday () in
  Printf.printf "Time for %s: %.3f seconds\n" name (end_time -. start_time);
  result

(* === Error Handling === *)
let safe_run name f =
  try
    Printf.printf "\nRunning %s...\n" name;
    f ();
    Printf.printf "%s completed successfully.\n" name
  with e ->
    Printf.printf "\nError in %s: %s\n" name (Printexc.to_string e)

(* === Helper Functions === *)
let create_xor_data num_samples =
  let features = Array.make_matrix num_samples 2 0.0 in
  let labels = Array.make num_samples 0.0 in
  for i = 0 to num_samples - 1 do
    let x1 = if Random.bool () then 1.0 else 0.0 in
    let x2 = if Random.bool () then 1.0 else 0.0 in
    features.(i) <- [|x1; x2|];
    labels.(i) <- if abs_float (x1 -. x2) > 0.5 then 1.0 else 0.0
  done;
  { features; labels }

let test_federated_learning () =
  Printf.printf "Testing Federated Learning:\n";
  let architecture = [|2; 4; 1|] in (* 2 inputs, 4 hidden, 1 output *)
  let model = create_model architecture in
  
  (* Create three clients with different data *)
  let client1_data = create_xor_data 100 in
  let client2_data = create_xor_data 150 in
  let client3_data = create_xor_data 120 in
  
  let config = {
    batch_size = 32;
    learning_rate = 0.1;
    num_epochs = 5;
  } in
  
  (* Train on each client *)
  let update1 = train_client model client1_data config in
  let update2 = train_client model client2_data config in
  let update3 = train_client model client3_data config in
  
  (* Aggregate updates *)
  let final_model = aggregate_updates [update1; update2; update3] in
  
  (* Evaluate model *)
  let test_data = create_xor_data 1000 in
  let accuracy = evaluate_model final_model test_data in
  Printf.printf "Final model accuracy: %.2f%%\n" (accuracy *. 100.0)

(* He Test*)
let test_homomorphic_encryption () =
  Printf.printf "\nTesting Homomorphic Encryption:\n";
  
  (* Create key rotation module *)
  let module KR = (val create_key_rotation 3600 1024) in
  let pk, sk = KR.current_key () in
  
  (* Test matrix operations *)
  let matrix1 = [|
    [|1.0; 2.0|];
    [|3.0; 4.0|]
  |] in
  let matrix2 = [|
    [|5.0; 6.0|];
    [|7.0; 8.0|]
  |] in
  
  let encrypted1 = encrypt_matrix pk matrix1 in
  let encrypted2 = encrypt_matrix pk matrix2 in
  
  (* Test matrix addition *)
  let sum = matrix_add pk encrypted1 encrypted2 in
  let decrypted_sum = decrypt_matrix pk sk sum in
  Printf.printf "Matrix addition result:\n";
  Array.iter (fun row ->
    Array.iter (fun x -> Printf.printf "%.1f " x) row;
    Printf.printf "\n"
  ) decrypted_sum;
  
  (* Test batch operations *)
  let values = [|1.0; 2.0; 3.0; 4.0; 5.0|] in
  let encrypted_batch = parallel_encrypt pk values in
  let decrypted_batch = parallel_decrypt pk sk encrypted_batch in
  Printf.printf "\nBatch operation result: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) decrypted_batch;
  Printf.printf "\n"

let test_differential_privacy () =
  Printf.printf "Testing Enhanced Differential Privacy:\n";
  
  (* Basic DP tests *)
  let privacy_params = create_privacy_params 0.1 1e-5 1.0 in
  let accountant = create_accountant Gaussian in
  
  let values = [|5.0; 10.0; 15.0; 20.0; 25.0|] in
  let accountant = update_privacy_budget accountant privacy_params in
  let (eps_spent, delta_spent) = compute_privacy_spent accountant in
  
  Printf.printf "Privacy accounting:\n";
  Printf.printf "Budget spent - Epsilon: %.4f, Delta: %.4f\n" eps_spent delta_spent;
  
  Printf.printf "\nNoise addition test:\n";
  Printf.printf "Original values: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) values;
  Printf.printf "\n";
  
  let noisy_values = add_noise_vector Gaussian privacy_params values in
  Printf.printf "Noisy values: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) noisy_values;
  Printf.printf "\n";

  (* Advanced DP tests *)
  Printf.printf "\nTesting advanced DP features:\n";
  let alpha_orders = [|1.5; 2.0; 2.5; 3.0; 3.5; 4.0|] in
  let moments_accountant = create_moments_accountant Gaussian alpha_orders in
  let rdp_params = compute_rdp moments_accountant 0.1 in
  Printf.printf "RDP parameters - Epsilon: %.4f\n" rdp_params;
  
  (* Local DP test *)
  let data = [|0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.7; 0.8; 0.9; 1.0|] in
  let private_mean = local_dp_mean data privacy_params in
  Printf.printf "Private mean: %.3f\n" private_mean;
  
  (* Histogram test *)
  let histogram = local_dp_histogram data 5 privacy_params in
  Printf.printf "Private histogram: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) histogram;
  Printf.printf "\n";
  
  (* Query tests *)
  let queries = Array.init 5 (fun i -> {
    value = float_of_int i;
    epsilon = 0.02;
    delta = 1e-6;
    sensitivity = 1.0;
  }) in
  let initial_budget = { epsilon = 0.1; delta = 1e-5; sensitivity = 1.0 } in
  let results, remaining_budget = manage_privacy_budget initial_budget queries in
  
  Printf.printf "\nPrivacy budget management:\n";
  Printf.printf "Query results: ";
  Array.iter (fun x -> Printf.printf "%.2f " x) results;
  Printf.printf "\nRemaining epsilon: %.3f\n" remaining_budget.epsilon

(* === Enhanced Matrix Operations Test === *)
let test_complex_matrix_operations config pk sk =
  Printf.printf "\nTesting complex matrix operations:\n";
  
  (* Create larger test matrices *)
  let size = config.matrix_size in
  let matrix1 = Array.make_matrix size size 1.0 in
  let matrix2 = Array.make_matrix size size 2.0 in
  
  (* Time matrix encryption *)
  let encrypted1 = time_operation "Matrix encryption" (fun () ->
    encrypt_matrix pk matrix1
  ) in
  let encrypted2 = time_operation "Matrix encryption" (fun () ->
    encrypt_matrix pk matrix2
  ) in
  
  (* Test matrix operations *)
  let sum = time_operation "Matrix addition" (fun () ->
    matrix_add pk encrypted1 encrypted2
  ) in
  
  (* Test decryption *)
  let _ = time_operation "Matrix decryption" (fun () ->
    decrypt_matrix pk sk sum
  ) in
  
  let _ = time_operation "Matrix multiplication" (fun () ->
    matrix_mult pk encrypted1 matrix2
  ) in
  
  (* Test parallel operations on larger arrays *)
  let large_array = Array.init (size * size) float_of_int in
  let encrypted = time_operation "Parallel encryption" (fun () ->
    parallel_encrypt pk large_array
  ) in
  let _ = time_operation "Parallel decryption" (fun () ->
    parallel_decrypt pk sk encrypted
  ) in
  
  Printf.printf "Complex matrix operations completed.\n"

(* === Main Entry Point with Configuration === *)
let run_tests config =
  Printf.printf "\nCryptaLearn Test Suite\n";
  Printf.printf "====================\n";
  Printf.printf "Configuration:\n";
  Printf.printf "  FL Samples: %d\n" config.fl_samples;
  Printf.printf "  Key Size: %d bits\n" config.key_size;
  Printf.printf "  Matrix Size: %dx%d\n" config.matrix_size config.matrix_size;
  Printf.printf "  DP Parameters: ε=%.2f, δ=%.2e\n" config.dp_epsilon config.dp_delta;
  
  if config.run_fl then
    safe_run "Federated Learning Tests" (fun () ->
      test_federated_learning ()
    );
  
  if config.run_he then
    safe_run "Homomorphic Encryption Tests" (fun () ->
      let module KR = (val create_key_rotation 3600 1024) in
      let pk, sk = KR.current_key () in
      test_homomorphic_encryption ();
      test_complex_matrix_operations config pk sk 
    );
  
  if config.run_dp then
    safe_run "Differential Privacy Tests" (fun () ->
      test_differential_privacy ()
    );
  
  Printf.printf "\nAll requested tests completed.\n"

(* === Command Line Arguments Processing === *)
let parse_args () =
  let config = ref default_config in
  let specs = [
    ("--fl-samples", Arg.Int (fun n -> config := { !config with fl_samples = n }), "Number of FL training samples");
    ("--key-size", Arg.Int (fun n -> config := { !config with key_size = n }), "Encryption key size in bits");
    ("--skip-fl", Arg.Unit (fun () -> config := { !config with run_fl = false }), "Skip federated learning tests");
    ("--skip-he", Arg.Unit (fun () -> config := { !config with run_he = false }), "Skip homomorphic encryption tests");
    ("--skip-dp", Arg.Unit (fun () -> config := { !config with run_dp = false }), "Skip differential privacy tests");
  ] in
  let usage = "Usage: " ^ Sys.argv.(0) ^ " [OPTIONS]" in
  Arg.parse specs (fun _ -> ()) usage;
  !config

let () =
  Random.self_init ();
  let config = parse_args () in
  run_tests config