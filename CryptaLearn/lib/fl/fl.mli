(* Federated Learning Core Functions *)

type activation = 
  | ReLU
  | Sigmoid
  | Tanh

type layer = {
  weights: float array array;  (* [|input_size x output_size|] *)
  biases: float array;        (* [|output_size|] *)
  activation: activation;
}

type model = {
  layers: layer array;
  architecture: int array;    (* Layer sizes including input and output *)
}

type client_data = {
  features: float array array;  (* [|num_samples x input_size|] *)
  labels: float array;          (* [|num_samples|] *)
}

type training_config = {
  batch_size: int;
  learning_rate: float;
  num_epochs: int;
}

type client_update = {
  model: model;
  num_samples: int;
  training_loss: float;
}

(* Core model operations *)
val create_model : int array -> model
val forward_pass : model -> float array -> float array array
val train_client : model -> client_data -> training_config -> client_update
val evaluate_model : model -> client_data -> float

(* Federated operations *)
val aggregate_updates : client_update list -> model
val serialize_model : model -> string
val deserialize_model : string -> model

(* Utility functions *)
val apply_activation : activation -> float -> float
val apply_activation_derivative : activation -> float -> float
val clip_gradients : float array array -> float -> float array array