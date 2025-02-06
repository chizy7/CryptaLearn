open Fl
open He
open Dp

let () =
  (* Simulating Federated Learning with 3 clients *)
  let model_updates = [0.8; 1.2; 0.9] in
  let aggregated_updates = federated_round 3 model_updates in
  Printf.printf "Aggregated Model Updates: [%s]\n"
    (String.concat "; " (List.map string_of_float aggregated_updates));

  (* Testing Homomorphic Encryption *)
  let encrypted = encrypt 1234 in
  let decrypted = decrypt encrypted in
  Printf.printf "Encrypted: %d, Decrypted: %d\n" encrypted decrypted;

  (* Applying Differential Privacy *)
  let private_value = add_noise 5.0 in
  Printf.printf "Private Value with Noise: %.2f\n" private_value;