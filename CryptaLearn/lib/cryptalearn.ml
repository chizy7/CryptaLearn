(* CryptaLearn Main Library Module *)

open Fl
open He
open Dp

(* === Configuration === *)
type test_config = {
  fl_samples: int;          (* Number of samples for FL training *)
  key_size: int;            (* Bit size for encryption keys *)
  matrix_size: int;         (* Size of test matrices *)
  dp_epsilon: float;        (* Privacy budget *)
  dp_delta: float;          (* Privacy failure probability *)
  run_fl: bool;             (* Whether to run FL tests *)
  run_he: bool;             (* Whether to run HE tests *)
  run_dp: bool;             (* Whether to run DP tests *)
  verification: bool;       (* Whether to verify test results *)
  seed: int option;         (* Random seed for reproducibility *)
  fail_on_error: bool;      (* Whether to abort on test errors *)
}

(* Default configuration with rationale *)
let default_config = {
  fl_samples = 100;         (* Sufficient for basic XOR learning while keeping tests fast *)
  key_size = 1024;          (* Standard RSA key size, balancing security and performance *)
  matrix_size = 2;          (* Small enough for quick tests, large enough to demonstrate functionality *)
  dp_epsilon = 0.1;         (* Conservative privacy budget for good privacy guarantees *)
  dp_delta = 1e-5;          (* Standard delta for (ε,δ)-DP, below 1/N for typical datasets *)
  run_fl = true;
  run_he = true;
  run_dp = true;
  verification = true;      (* Enable result verification by default *)
  seed = None;              (* Use random seed by default *)
  fail_on_error = false;    (* Don't abort by default to run all possible tests *)
}

(* === Timing Utilities === *)
let time_operation name f =
  let start_time = Unix.gettimeofday () in
  let result = f () in
  let end_time = Unix.gettimeofday () in
  Printf.printf "Time for %s: %.3f seconds\n" name (end_time -. start_time);
  result

(* === Error Handling === *)
let safe_run name f config =
  try
    Printf.printf "\nRunning %s...\n" name;
    f ();
    Printf.printf "%s completed successfully.\n" name;
    true
  with e ->
    let error_msg = Printf.sprintf "\nError in %s: %s\n" name (Printexc.to_string e) in
    Printf.eprintf "%s" error_msg;

    (* Optionally abort the process on error *)
    if config.fail_on_error then begin
      Printf.eprintf "Aborting due to test failure.\n";
      exit 1
    end;
    false

(* === Helper Functions === *)
let create_xor_data ?seed num_samples =
  (* Initialize random seed if provided for reproducibility *)
  (match seed with
  | Some s -> Random.init s
  | None -> ());

  let features = Array.make_matrix num_samples 2 0.0 in
  let labels = Array.make num_samples 0.0 in
  for i = 0 to num_samples - 1 do
    let x1 = if Random.bool () then 1.0 else 0.0 in
    let x2 = if Random.bool () then 1.0 else 0.0 in
    features.(i) <- [|x1; x2|];
    labels.(i) <- if abs_float (x1 -. x2) > 0.5 then 1.0 else 0.0
  done;
  { features; labels }

(* === Matrix Comparison Utility === *)
let matrices_equal m1 m2 epsilon =
  let rows = Array.length m1 in
  let cols = Array.length m1.(0) in

  if rows != Array.length m2 || cols != Array.length m2.(0) then
    false
  else
    try
      for i = 0 to rows - 1 do
        for j = 0 to cols - 1 do
          if abs_float (m1.(i).(j) -. m2.(i).(j)) > epsilon then
            raise Exit
        done
      done;
      true
    with Exit -> false

let vectors_equal v1 v2 epsilon =
  if Array.length v1 != Array.length v2 then
    false
  else
    try
      for i = 0 to Array.length v1 - 1 do
        if abs_float (v1.(i) -. v2.(i)) > epsilon then
          raise Exit
      done;
      true
    with Exit -> false

(* === Test Functions === *)
let test_federated_learning config =
  Printf.printf "Testing Federated Learning:\n";

  (* Set seed if specified *)
  (match config.seed with
  | Some s -> Random.init s
  | None -> ());

  let architecture = [|2; 4; 1|] in (* 2 inputs, 4 hidden, 1 output *)
  let model = create_model architecture in

  (* Create three clients with different data *)
  let client1_data = create_xor_data ?seed:config.seed config.fl_samples in
  let client2_data = create_xor_data ?seed:config.seed (config.fl_samples * 3 / 2) in
  let client3_data = create_xor_data ?seed:config.seed (config.fl_samples * 6 / 5) in

  let fl_config = {
    batch_size = 32;
    learning_rate = 0.1;
    num_epochs = 5;
  } in

  (* Train on each client *)
  let update1 = train_client model client1_data fl_config in
  let update2 = train_client model client2_data fl_config in
  let update3 = train_client model client3_data fl_config in

  (* Aggregate updates *)
  let final_model = aggregate_updates [update1; update2; update3] in

  (* Evaluate model *)
  let test_data = create_xor_data ?seed:config.seed 1000 in
  let accuracy = evaluate_model final_model test_data in
  Printf.printf "Final model accuracy (standard FL): %.2f%%\n" (accuracy *. 100.0);

  (* Verify results if requested *)
  if config.verification then begin
    (* For XOR problem in a federated setting, we expect >70% accuracy *)
    if accuracy < 0.70 then
      failwith (Printf.sprintf "Model accuracy too low: %.2f%%" (accuracy *. 100.0));
    Printf.printf "✓ Accuracy verification passed (>70%%)\n";
  end

let test_dp_sgd config =
  Printf.printf "\nTesting DP-SGD (Differential Privacy + Federated Learning):\n";

  (* Set seed if specified *)
  (match config.seed with
  | Some s -> Random.init s
  | None -> ());

  let architecture = [|2; 4; 1|] in
  let model = create_model architecture in

  (* Create client data *)
  let client_data = create_xor_data ?seed:config.seed config.fl_samples in

  (* Calculate noise multiplier from epsilon-delta budget *)
  let noise_multiplier =
    1.0 *. sqrt(2.0 *. log(1.25 /. config.dp_delta)) /. config.dp_epsilon in

  let dp_config = {
    batch_size = 32;
    learning_rate = 0.1;
    num_epochs = 5;
    clip_norm = 1.0;
    noise_multiplier = noise_multiplier;
    dp_epsilon = config.dp_epsilon;
    dp_delta = config.dp_delta;
  } in

  (* Train with DP-SGD *)
  let dp_update = train_client_dp_sgd model client_data dp_config in

  (* Evaluate *)
  let test_data = create_xor_data ?seed:config.seed 1000 in
  let dp_accuracy = evaluate_model dp_update.model test_data in

  Printf.printf "DP-SGD accuracy (ε=%.2f, σ=%.2f): %.2f%%\n"
    config.dp_epsilon noise_multiplier (dp_accuracy *. 100.0);

  (* Expected: accuracy decreases with stronger privacy (lower epsilon) *)
  if config.verification then begin
    Printf.printf "✓ DP-SGD training completed\n";
    Printf.printf "  Privacy-utility tradeoff: ε=%.2f → %.2f%% accuracy\n"
      config.dp_epsilon (dp_accuracy *. 100.0);
  end

let test_homomorphic_encryption config =
  Printf.printf "\nTesting Homomorphic Encryption:\n";

  (* Create key rotation module *)
  let module KR = (val create_key_rotation 3600 config.key_size) in
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

  (* Verify matrix addition if requested *)
  if config.verification then begin
    let expected_sum = [|
      [|6.0; 8.0|];
      [|10.0; 12.0|]
    |] in

    if not (matrices_equal decrypted_sum expected_sum 1e-7) then
      failwith "Matrix addition verification failed: results don't match expected values";
    Printf.printf "✓ Matrix addition verification passed\n";
  end;

  (* Test batch operations *)
  let values = [|1.0; 2.0; 3.0; 4.0; 5.0|] in
  let encrypted_batch = parallel_encrypt pk values in
  let decrypted_batch = parallel_decrypt pk sk encrypted_batch in
  Printf.printf "\nBatch operation result: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) decrypted_batch;
  Printf.printf "\n";

  (* Verify batch operations if requested *)
  if config.verification then begin
    if not (vectors_equal decrypted_batch values 1e-7) then
      failwith "Batch encryption/decryption verification failed: results don't match input values";
    Printf.printf "✓ Batch operation verification passed\n";
  end

let test_differential_privacy config =
  Printf.printf "Testing Enhanced Differential Privacy:\n";

  (* Basic DP tests *)
  let privacy_params = create_privacy_params config.dp_epsilon config.dp_delta 1.0 in
  let accountant = create_accountant Gaussian in

  let values = [|5.0; 10.0; 15.0; 20.0; 25.0|] in
  let accountant = update_privacy_budget accountant privacy_params in
  let (eps_spent, delta_spent) = compute_privacy_spent accountant in

  Printf.printf "Privacy accounting:\n";
  Printf.printf "Budget spent - Epsilon: %.4f, Delta: %.4f\n" eps_spent delta_spent;

  (* Verify privacy accounting if requested *)
  if config.verification then begin
    if eps_spent <= 0.0 || eps_spent > config.dp_epsilon then
      failwith (Printf.sprintf "Privacy accounting verification failed: epsilon spent (%.4f) outside expected range" eps_spent);
    Printf.printf "✓ Privacy accounting verification passed\n";
  end;

  Printf.printf "\nNoise addition test:\n";
  Printf.printf "Original values: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) values;
  Printf.printf "\n";

  let noisy_values = add_noise_vector Gaussian privacy_params values in
  Printf.printf "Noisy values: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) noisy_values;
  Printf.printf "\n";

  (* Verify noise addition if requested *)
  if config.verification then begin
    (* Check that noise has been added (values should be different) *)
    let has_noise = not (vectors_equal values noisy_values 1e-7) in
    if not has_noise then
      failwith "Noise addition verification failed: no noise was added";

    (* Check that the noise magnitude is reasonable *)
    let avg_noise = Array.fold_left (fun acc i ->
      acc +. abs_float(values.(i) -. noisy_values.(i))
    ) 0.0 (Array.init (Array.length values) (fun i -> i)) /. float_of_int (Array.length values) in

    (* For Gaussian noise with our params, expected noise should be on an order of magnitude related to sensitivity/epsilon *)
    let expected_magnitude = privacy_params.sensitivity /. privacy_params.epsilon in
    if avg_noise > expected_magnitude *. 10.0 then
      failwith (Printf.sprintf "Noise magnitude verification failed: average noise (%.2f) is too large" avg_noise);

    Printf.printf "✓ Noise addition verification passed (avg noise: %.2f)\n" avg_noise;
  end;

  (* Advanced DP tests *)
  Printf.printf "\nTesting advanced DP features:\n";
  let alpha_orders = [|1.5; 2.0; 2.5; 3.0; 3.5; 4.0|] in
  let moments_accountant = create_moments_accountant Gaussian alpha_orders in
  let rdp_params = compute_rdp moments_accountant 0.1 in
  Printf.printf "RDP parameters - Epsilon: %.4f\n" rdp_params;

  (* Local DP test *)
  let data = [|0.1; 0.2; 0.3; 0.4; 0.5; 0.6; 0.7; 0.8; 0.9; 1.0|] in
  let private_mean = local_dp_mean data privacy_params in
  let true_mean = Array.fold_left (+.) 0.0 data /. float_of_int (Array.length data) in
  Printf.printf "True mean: %.3f, Private mean: %.3f\n" true_mean private_mean;

  (* Verify private mean if requested *)
  if config.verification then begin
    (* Private mean should be close to true mean, but not exactly equal *)
    if abs_float (private_mean -. true_mean) < 1e-7 then
      failwith "Private mean verification failed: output is not privatized";

    (* But it shouldn't be too far off either *)
    if abs_float (private_mean -. true_mean) > 2.0 then
      failwith (Printf.sprintf "Private mean verification failed: error too large (%.3f)" (abs_float (private_mean -. true_mean)));

    Printf.printf "✓ Private mean verification passed\n";
  end;

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
  Printf.printf "\nRemaining epsilon: %.3f\n" remaining_budget.epsilon;

  (* Verify budget management if requested *)
  if config.verification then begin
    if remaining_budget.epsilon < 0.0 then
      failwith "Budget management verification failed: negative remaining epsilon";

    if remaining_budget.epsilon > initial_budget.epsilon then
      failwith "Budget management verification failed: remaining budget exceeds initial budget";

    Printf.printf "✓ Budget management verification passed\n";
  end

(* === Enhanced Matrix Operations Test === *)
let test_complex_matrix_operations config pk sk =
  Printf.printf "\nTesting complex matrix operations:\n";

  (* Create larger test matrices *)
  let size = config.matrix_size in
  let matrix1 = Array.make_matrix size size 1.0 in
  let matrix2 = Array.make_matrix size size 2.0 in

  (* Create expected results for verification *)
  let expected_sum = Array.make_matrix size size 3.0 in
  let expected_mult = Array.make_matrix size size (2.0 *. float_of_int size) in

  (* Time matrix encryption *)
  let encrypted1 = time_operation "Matrix encryption" (fun () ->
    encrypt_matrix pk matrix1
  ) in
  let encrypted2 = time_operation "Matrix encryption" (fun () ->
    encrypt_matrix pk matrix2
  ) in

  (* Test matrix addition *)
  let sum = time_operation "Matrix addition" (fun () ->
    matrix_add pk encrypted1 encrypted2
  ) in

  (* Test decryption *)
  let decrypted_sum = time_operation "Matrix decryption" (fun () ->
    decrypt_matrix pk sk sum
  ) in

  (* Verify addition result if requested *)
  if config.verification then begin
    if not (matrices_equal decrypted_sum expected_sum 1e-7) then
      failwith "Complex matrix addition verification failed";
    Printf.printf "✓ Matrix addition verification passed\n";
  end;

  (* Test matrix multiplication *)
  let mult_result = time_operation "Matrix multiplication" (fun () ->
    matrix_mult pk encrypted1 matrix2
  ) in

  (* Decrypt multiplication result *)
  let decrypted_mult = decrypt_matrix pk sk mult_result in

  (* Verify multiplication result if requested *)
  if config.verification then begin
    if not (matrices_equal decrypted_mult expected_mult 1e-7) then
      failwith "Complex matrix multiplication verification failed";
    Printf.printf "✓ Matrix multiplication verification passed\n";
  end;

  (* Test parallel operations on larger arrays *)
  let large_array = Array.init (size * size) float_of_int in
  let encrypted = time_operation "Parallel encryption" (fun () ->
    parallel_encrypt pk large_array
  ) in
  let decrypted = time_operation "Parallel decryption" (fun () ->
    parallel_decrypt pk sk encrypted
  ) in

  (* Verify parallel operations if requested *)
  if config.verification then begin
    if not (vectors_equal large_array decrypted 1e-7) then
      failwith "Parallel encryption/decryption verification failed";
    Printf.printf "✓ Parallel operations verification passed\n";
  end;

  Printf.printf "Complex matrix operations completed.\n"

(* === Main Test Runner === *)
let run_tests config =
  Printf.printf "\nCryptaLearn Test Suite\n";
  Printf.printf "====================\n";
  Printf.printf "Configuration:\n";
  Printf.printf "  FL Samples: %d\n" config.fl_samples;
  Printf.printf "  Key Size: %d bits\n" config.key_size;
  Printf.printf "  Matrix Size: %dx%d\n" config.matrix_size config.matrix_size;
  Printf.printf "  DP Parameters: ε=%.2f, δ=%.2e\n" config.dp_epsilon config.dp_delta;
  Printf.printf "  Verification: %s\n" (if config.verification then "Enabled" else "Disabled");
  Printf.printf "  Seed: %s\n" (match config.seed with Some s -> string_of_int s | None -> "Random");
  Printf.printf "  Fail on error: %s\n" (if config.fail_on_error then "Yes" else "No");

  let all_success = ref true in

  if config.run_fl then begin
    all_success := !all_success && safe_run "Federated Learning Tests" (fun () ->
      test_federated_learning config
    ) config;

    (* Also run DP-SGD test to show privacy-utility tradeoff *)
    all_success := !all_success && safe_run "DP-SGD Tests" (fun () ->
      test_dp_sgd config
    ) config;
  end;

  if config.run_he then
    all_success := !all_success && safe_run "Homomorphic Encryption Tests" (fun () ->
      let module KR = (val create_key_rotation 3600 config.key_size) in
      let pk, sk = KR.current_key () in
      test_homomorphic_encryption config;
      test_complex_matrix_operations config pk sk
    ) config;

  if config.run_dp then
    all_success := !all_success && safe_run "Differential Privacy Tests" (fun () ->
      test_differential_privacy config
    ) config;

  if !all_success then
    Printf.printf "\nAll requested tests completed successfully.\n"
  else
    Printf.printf "\nSome tests failed. Check the logs for details.\n";

  !all_success
