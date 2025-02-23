(* Federated Learning Interface *)

(* === Basic Types === *)
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

(* === Training Types === *)
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

(* === Versioning Types === *)
type version = {
  major: int;
  minor: int;
  patch: int;
  timestamp: float;
}

type model_metadata = {
  version: version;
  architecture: int array;
  created_at: float;
  updated_at: float;
  training_rounds: int;
  total_clients: int;
}

type versioned_model = {
  metadata: model_metadata;
  model: model;
}

(* === Core Model Operations === *)
val create_model : int array -> model
val forward_pass : model -> float array -> float array array
val train_client : model -> client_data -> training_config -> client_update
val evaluate_model : model -> client_data -> float

(* === Federated Operations === *)
val aggregate_updates : client_update list -> model
val serialize_model : model -> string
val deserialize_model : string -> model

(* === Utility Functions === *)
val apply_activation : activation -> float -> float
val apply_activation_derivative : activation -> float -> float
val clip_gradients : float array array -> float -> float array array

(* === Version Management === *)
val create_version : int -> int -> int -> version
val increment_version : version -> [`Major | `Minor | `Patch] -> version
val version_to_string : version -> string
val compare_versions : version -> version -> int

(* === Model Versioning === *)
val create_versioned_model : model -> model_metadata -> versioned_model
val update_model_metadata : versioned_model -> model -> versioned_model
val is_compatible_version : versioned_model -> versioned_model -> bool

(* === Secure Aggregation === *)
val secure_aggregate : versioned_model list -> float array -> versioned_model