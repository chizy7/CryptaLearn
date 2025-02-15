open Fl
open He
open Dp

let () =
  (* Test Federated Learning *)
  Printf.printf "Testing Federated Learning:\n";
  let architecture = [|2; 4; 1|] in (* 2 inputs, 4 hidden, 1 output *)
  let model = create_model architecture in
  
  (* Create synthetic training data *)
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
  in
  
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
  Printf.printf "Final model accuracy: %.2f%%\n" (accuracy *. 100.0);

  (* Test Homomorphic Encryption *)
  Printf.printf "\nTesting Homomorphic Encryption:\n";
  let pk, sk = generate_keypair 1024 in
  
  (* Test encryption/decryption *)
  let value = Z.of_int 42 in
  let encrypted = encrypt pk value in
  let decrypted = decrypt pk sk encrypted in
  Printf.printf "Single value test - Original: %s, Decrypted: %s\n"
    (Z.to_string value) (Z.to_string decrypted);
  
  (* Test homomorphic addition *)
  let value1 = Z.of_int 30 in
  let value2 = Z.of_int 12 in
  let enc1 = encrypt pk value1 in
  let enc2 = encrypt pk value2 in
  let enc_sum = add pk enc1 enc2 in
  let dec_sum = decrypt pk sk enc_sum in
  Printf.printf "Homomorphic addition test - 30 + 12 = %s\n" (Z.to_string dec_sum);

  (* Test Differential Privacy *)
  Printf.printf "\nTesting Differential Privacy:\n";
  let privacy_params = create_privacy_params 0.1 1e-5 1.0 in
  let accountant = create_accountant Gaussian in
  
  (* Test noise addition and privacy accounting *)
  let values = [|5.0; 10.0; 15.0; 20.0; 25.0|] in
  let accountant = update_privacy_budget accountant privacy_params in
  let (eps_spent, delta_spent) = compute_privacy_spent accountant in
  Printf.printf "Privacy budget spent - Epsilon: %.4f, Delta: %.4f\n" eps_spent delta_spent;
  Printf.printf "Original values: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) values;
  Printf.printf "\n";
  
  let noisy_values = add_noise_vector Gaussian privacy_params values in
  Printf.printf "Noisy values: ";
  Array.iter (fun x -> Printf.printf "%.1f " x) noisy_values;
  Printf.printf "\n";
  
  (* Test gradient clipping *)
  let gradients = [|1.5; 2.5; 3.5; 4.5; 5.5|] in
  let clipped = clip_gradients gradients 3.0 in
  Printf.printf "Gradient clipping test - Original norm: %.2f, Clipped norm: %.2f\n"
    (sqrt (Array.fold_left (fun acc x -> acc +. x *. x) 0.0 gradients))
    (sqrt (Array.fold_left (fun acc x -> acc +. x *. x) 0.0 clipped));