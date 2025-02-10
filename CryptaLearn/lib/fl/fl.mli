(* Federated Learning Core Functions *)

type model = float array
type client_update = {
  weights: model;
  num_samples: int;
}

val initialize_model : int -> model
val aggregate_models : client_update list -> model
val train_round : model -> client_update list -> model
val federated_average : client_update list -> model