open Fl
open He
open Dp

let () =
  (* Initialize federated learning *)
  let model_size = 10 in
  let initial_model = initialize_model model_size in
  
  (* Simulate client updates *)
  let client_updates = [
    { weights = Array.map (fun x -> x +. 0.1) initial_model; num_samples = 100 };
    { weights = Array.map (fun x -> x +. 0.2) initial_model; num_samples = 150 };
    { weights = Array.map (fun x -> x +. 0.15) initial_model; num_samples = 120 };
  ] in
  
  (* Perform federated averaging *)
  let aggregated_model = federated_average client_updates in
  Printf.printf "Aggregated Model First 3 Weights: [%f; %f; %f]\n"
    aggregated_model.(0) aggregated_model.(1) aggregated_model.(2);

  (* Test homomorphic encryption *)
  let pk, sk = generate_keypair 1024 in
  let value = Z.of_int 42 in
  let encrypted = encrypt pk value in
  let decrypted = decrypt pk sk encrypted in
  Printf.printf "Original: %s, Decrypted: %s\n"
    (Z.to_string value) (Z.to_string decrypted);

  (* Test differential privacy *)
  let privacy_params = create_privacy_params 0.1 1e-5 1.0 in
  let private_value = 5.0 in
  let noisy_value = add_laplace_noise privacy_params private_value in
  Printf.printf "Original: %f, Private: %f\n" private_value noisy_value;
  
  (* Test gradient clipping *)
  let gradients = [|1.5; 2.5; 3.5; 4.5; 5.5|] in
  let clipped = clip_gradients gradients 3.0 in
  Printf.printf "Clipped gradient norm: %f\n"
    (sqrt (Array.fold_left (fun acc x -> acc +. x *. x) 0.0 clipped));