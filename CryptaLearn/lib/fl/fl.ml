(* Federated Learning Module *)

let federated_round num_clients module_updates = 
  let avg_update = List.fold_left ( +. ) 0.0 module_updates /. float_of_int num_clients in 
  List.map (fun _ -> avg_update) module_updates