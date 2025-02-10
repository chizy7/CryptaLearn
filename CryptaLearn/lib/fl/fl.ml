(* Federated Learning Module *)

type model = float array
type client_update = {
  weights: model;
  num_samples: int;
}

let initialize_model size =
  Array.init size (fun _ -> Random.float 1.0)

(* FedAvg algorithm implementation *)
let aggregate_models updates =
  let total_samples = List.fold_left (fun acc u -> acc + u.num_samples) 0 updates in
  let num_weights = Array.length (List.hd updates).weights in
  let weighted_sum = Array.make num_weights 0.0 in
  
  List.iter (fun update ->
    let weight = float_of_int update.num_samples /. float_of_int total_samples in
    Array.iteri (fun i w ->
      weighted_sum.(i) <- weighted_sum.(i) +. w *. weight
    ) update.weights
  ) updates;
  
  weighted_sum

let train_round global_model client_updates =
  (* Perform federated averaging *)
  let new_model = aggregate_models client_updates in
  (* Apply learning rate to the difference between new and global model *)
  let learning_rate = 0.1 in
  Array.mapi (fun i w -> 
    global_model.(i) +. learning_rate *. (w -. global_model.(i))
  ) new_model

let federated_average updates =
  if List.length updates = 0 then
    [||]
  else
    aggregate_models updates