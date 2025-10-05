(* Test Suite for CryptaLearn *)

open Fl
open He
open Dp

(* === Test Utilities === *)
let assert_true condition message =
  if not condition then
    failwith ("Assertion failed: " ^ message)

let assert_float_equal expected actual tolerance message =
  let diff = abs_float (expected -. actual) in
  if diff > tolerance then
    failwith (Printf.sprintf "Assertion failed: %s (expected: %.4f, got: %.4f, diff: %.4f)"
      message expected actual diff)

let assert_array_equal expected actual tolerance message =
  if Array.length expected <> Array.length actual then
    failwith (message ^ " - array length mismatch");
  Array.iteri (fun i exp ->
    let diff = abs_float (exp -. actual.(i)) in
    if diff > tolerance then
      failwith (Printf.sprintf "%s - element %d differs (expected: %.4f, got: %.4f)"
        message i exp actual.(i))
  ) expected

(* === Federated Learning Tests === *)
let test_model_creation () =
  Printf.printf "Testing model creation...\n";
  let architecture = [|2; 3; 1|] in
  let model = create_model architecture in

  (* architecture [2; 3; 1] means: 2 inputs, 3 hidden, 1 output
     This creates 2 layers: input→hidden and hidden→output *)
  assert_true (Array.length model.layers = 2) "Model should have 2 layers";
  (* First layer: weights matrix is input_size × output_size = 2×3 *)
  assert_true (Array.length model.layers.(0).weights = 2) "First layer weights should have 2 rows (inputs)";
  assert_true (Array.length model.layers.(0).weights.(0) = 3) "First layer should have 3 columns (outputs)";
  assert_true (Array.length model.layers.(0).biases = 3) "First layer should have 3 biases (outputs)";
  Printf.printf "  ✓ Model creation test passed\n"

let test_training () =
  Printf.printf "Testing FL training...\n";
  Random.init 42;

  let model = create_model [|2; 2; 1|] in
  let data = {
    features = [|[|0.0; 0.0|]; [|1.0; 1.0|]|];
    labels = [|0.0; 0.0|]
  } in

  let config = { batch_size = 2; learning_rate = 0.1; num_epochs = 1 } in
  let update = train_client model data config in

  assert_true (update.num_samples = 2) "Should process 2 samples";
  assert_true (update.training_loss >= 0.0) "Loss should be non-negative";
  Printf.printf "  ✓ FL training test passed (loss: %.4f)\n" update.training_loss

let test_fl_aggregation () =
  Printf.printf "Testing FL aggregation...\n";
  Random.init 42;

  let model = create_model [|2; 2; 1|] in
  let data = {
    features = [|[|0.0; 0.0|]; [|1.0; 1.0|]|];
    labels = [|0.0; 0.0|]
  } in

  let config = { batch_size = 2; learning_rate = 0.1; num_epochs = 1 } in
  let update1 = train_client model data config in
  let update2 = train_client model data config in

  let aggregated = aggregate_updates [update1; update2] in

  assert_true (Array.length aggregated.layers = 2) "Aggregated model should preserve structure";
  Printf.printf "  ✓ FL aggregation test passed\n"

let test_dp_sgd () =
  Printf.printf "Testing DP-SGD...\n";
  Random.init 42;

  let model = create_model [|2; 3; 1|] in
  let data = {
    features = [|[|0.0; 0.0|]; [|1.0; 0.0|]; [|0.0; 1.0|]; [|1.0; 1.0|]|];
    labels = [|0.0; 1.0; 1.0; 0.0|]
  } in

  let dp_config = {
    batch_size = 2;
    learning_rate = 0.1;
    num_epochs = 2;
    clip_norm = 1.0;
    noise_multiplier = 1.0;
    dp_epsilon = 1.0;
    dp_delta = 1e-5;
  } in

  let update = train_client_dp_sgd model data dp_config in

  assert_true (update.num_samples = 4) "Should process all 4 samples";
  assert_true (update.training_loss >= 0.0) "Training loss should be non-negative";
  Printf.printf "  ✓ DP-SGD test passed (loss: %.4f)\n" update.training_loss

(* === Homomorphic Encryption Tests === *)
let test_key_generation () =
  Printf.printf "Testing HE key generation...\n";
  let (pk, sk) = generate_keypair 512 in (* Small key for fast testing *)

  let module PK = (val pk : PublicKey) in
  let module SK = (val sk : PrivateKey) in

  assert_true (Z.gt PK.n Z.zero) "Public key n should be positive";
  assert_true (Z.gt SK.lambda Z.zero) "Private key lambda should be positive";
  Printf.printf "  ✓ Key generation test passed\n"

let test_encryption_decryption () =
  Printf.printf "Testing encryption/decryption...\n";
  let (pk, sk) = generate_keypair 512 in

  let plaintext = Z.of_int 42 in
  let ciphertext = encrypt pk plaintext in
  let decrypted = decrypt pk sk ciphertext in

  assert_true (Z.equal plaintext decrypted) "Decryption should recover plaintext";
  Printf.printf "  ✓ Encryption/decryption test passed\n"

let test_homomorphic_addition () =
  Printf.printf "Testing homomorphic addition...\n";
  let (pk, sk) = generate_keypair 512 in

  let m1 = Z.of_int 10 in
  let m2 = Z.of_int 32 in
  let c1 = encrypt pk m1 in
  let c2 = encrypt pk m2 in

  let c_sum = add pk c1 c2 in
  let m_sum = decrypt pk sk c_sum in

  assert_true (Z.equal m_sum (Z.add m1 m2)) "Homomorphic addition should work";
  Printf.printf "  ✓ Homomorphic addition test passed\n"

let test_homomorphic_multiplication () =
  Printf.printf "Testing homomorphic scalar multiplication...\n";
  let (pk, sk) = generate_keypair 512 in

  let m = Z.of_int 7 in
  let scalar = Z.of_int 3 in
  let c = encrypt pk m in

  let c_mult = mult pk c scalar in
  let m_mult = decrypt pk sk c_mult in

  assert_true (Z.equal m_mult (Z.mul m scalar)) "Homomorphic multiplication should work";
  Printf.printf "  ✓ Homomorphic multiplication test passed\n"

let test_vector_operations () =
  Printf.printf "Testing HE vector operations...\n";
  let (pk, sk) = generate_keypair 512 in

  let vec = [|1.0; 2.0; 3.0|] in
  let encrypted = encrypt_vector pk vec in
  let decrypted = decrypt_vector pk sk encrypted in

  assert_array_equal vec decrypted 1e-6 "Vector encryption/decryption";
  Printf.printf "  ✓ Vector operations test passed\n"

let test_matrix_operations () =
  Printf.printf "Testing HE matrix operations...\n";
  let (pk, sk) = generate_keypair 512 in

  let m1 = [|[|1.0; 2.0|]; [|3.0; 4.0|]|] in
  let m2 = [|[|5.0; 6.0|]; [|7.0; 8.0|]|] in

  let enc1 = encrypt_matrix pk m1 in
  let enc2 = encrypt_matrix pk m2 in
  let enc_sum = matrix_add pk enc1 enc2 in
  let dec_sum = decrypt_matrix pk sk enc_sum in

  assert_float_equal 6.0 dec_sum.(0).(0) 1e-6 "Matrix addition [0,0]";
  assert_float_equal 8.0 dec_sum.(0).(1) 1e-6 "Matrix addition [0,1]";
  assert_float_equal 10.0 dec_sum.(1).(0) 1e-6 "Matrix addition [1,0]";
  assert_float_equal 12.0 dec_sum.(1).(1) 1e-6 "Matrix addition [1,1]";
  Printf.printf "  ✓ Matrix operations test passed\n"

(* === Differential Privacy Tests === *)
let test_privacy_params () =
  Printf.printf "Testing privacy parameters...\n";
  let params = create_privacy_params 0.5 1e-5 1.0 in

  assert_float_equal 0.5 params.epsilon 1e-9 "Epsilon should match";
  assert_float_equal 1e-5 params.delta 1e-9 "Delta should match";
  assert_float_equal 1.0 params.sensitivity 1e-9 "Sensitivity should match";
  Printf.printf "  ✓ Privacy parameters test passed\n"

let test_noise_addition () =
  Printf.printf "Testing noise addition...\n";
  Random.init 42;

  let params = create_privacy_params 1.0 1e-5 1.0 in
  let value = 10.0 in
  let noisy_value = add_noise Gaussian params value in

  (* Noise should change the value *)
  assert_true (abs_float (noisy_value -. value) > 0.01) "Noise should be added";
  Printf.printf "  ✓ Noise addition test passed (noise: %.2f)\n"
    (abs_float (noisy_value -. value))

let test_gradient_clipping () =
  Printf.printf "Testing gradient clipping...\n";
  let gradients = [|3.0; 4.0|] in  (* Norm = 5.0 *)
  let clip_norm = 1.0 in

  let clipped = clip_gradients gradients clip_norm in
  let norm = sqrt (Array.fold_left (fun acc g -> acc +. g *. g) 0.0 clipped) in

  assert_float_equal 1.0 norm 1e-6 "Clipped gradient norm should equal clip_norm";
  Printf.printf "  ✓ Gradient clipping test passed\n"

let test_privacy_accounting () =
  Printf.printf "Testing privacy accounting...\n";
  let params = create_privacy_params 0.1 1e-5 1.0 in
  let accountant = create_accountant Gaussian in

  let updated_accountant = update_privacy_budget accountant params in
  let (eps_spent, _delta_spent) = compute_privacy_spent updated_accountant in

  assert_true (eps_spent > 0.0) "Epsilon spent should be positive";
  assert_true (eps_spent <= params.epsilon) "Epsilon spent should not exceed budget";
  Printf.printf "  ✓ Privacy accounting test passed (ε=%.4f)\n" eps_spent

let test_local_dp_mean () =
  Printf.printf "Testing local DP mean...\n";
  Random.init 42;

  let data = Array.init 100 (fun i -> float_of_int i) in
  let true_mean = 49.5 in (* Average of 0..99 *)
  let params = create_privacy_params 1.0 1e-5 1.0 in

  let private_mean = local_dp_mean data params in

  (* Private mean should be close to true mean but not exact *)
  let error = abs_float (private_mean -. true_mean) in
  assert_true (error > 0.01) "Private mean should differ from true mean";
  assert_true (error < 50.0) "Private mean should be reasonably close";
  Printf.printf "  ✓ Local DP mean test passed (error: %.2f)\n" error

(* === Main Test Runner === *)
let () =
  Printf.printf "\n╔════════════════════════════════════════════════════════════╗\n";
  Printf.printf "║          CryptaLearn Test Suite                              ║\n";
  Printf.printf "╚════════════════════════════════════════════════════════════╝\n\n";

  let run_test name test_fn =
    try
      test_fn ();
      true
    with e ->
      Printf.printf "  ✗ %s failed: %s\n" name (Printexc.to_string e);
      false
  in

  Printf.printf "══ Federated Learning Tests ══\n";
  let fl_tests = [
    ("Model Creation", test_model_creation);
    ("FL Training", test_training);
    ("FL Aggregation", test_fl_aggregation);
    ("DP-SGD Training", test_dp_sgd);
  ] in

  Printf.printf "\n══ Homomorphic Encryption Tests ══\n";
  let he_tests = [
    ("Key Generation", test_key_generation);
    ("Encryption/Decryption", test_encryption_decryption);
    ("Homomorphic Addition", test_homomorphic_addition);
    ("Homomorphic Multiplication", test_homomorphic_multiplication);
    ("Vector Operations", test_vector_operations);
    ("Matrix Operations", test_matrix_operations);
  ] in

  Printf.printf "\n══ Differential Privacy Tests ══\n";
  let dp_tests = [
    ("Privacy Parameters", test_privacy_params);
    ("Noise Addition", test_noise_addition);
    ("Gradient Clipping", test_gradient_clipping);
    ("Privacy Accounting", test_privacy_accounting);
    ("Local DP Mean", test_local_dp_mean);
  ] in

  let all_tests = fl_tests @ he_tests @ dp_tests in
  let results = List.map (fun (name, test) -> run_test name test) all_tests in
  let passed = List.fold_left (fun acc passed -> if passed then acc + 1 else acc) 0 results in
  let total = List.length results in

  Printf.printf "\n╔════════════════════════════════════════════════════════════╗\n";
  Printf.printf "║ Test Results: %d/%d passed (%.1f%%)                        ║\n"
    passed total (100.0 *. float_of_int passed /. float_of_int total);
  Printf.printf "╚════════════════════════════════════════════════════════════╝\n";

  if passed < total then exit 1
