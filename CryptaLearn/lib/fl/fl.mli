(** Federated Learning Interface 
    This module provides types and functions for implementing federated learning,
    including model management, training, and secure aggregation. *)

(* === Basic Types === *)
(** Activation function types for neural network layers *)
type activation = 
  | ReLU     (** Rectified Linear Unit: f(x) = max(0, x) *)
  | Sigmoid  (** Sigmoid function: f(x) = 1 / (1 + e^(-x)) *)
  | Tanh     (** Hyperbolic tangent: f(x) = tanh(x) *)

(** Neural network layer representation *)
type layer = {
  weights: float array array;  (** [|input_size x output_size|] Weight matrix *)
  biases: float array;         (** [|output_size|] Bias vector *)
  activation: activation;      (** Activation function applied to layer outputs *)
}

(** Complete neural network model representation *)
type model = {
  layers: layer array;         (** Array of layers in the network *)
  architecture: int array;     (** Layer sizes including input and output dimensions *)
}

(* === Training Types === *)
(** Client-side training data *)
type client_data = {
  features: float array array;  (** [|num_samples x input_size|] Input features *)
  labels: float array;          (** [|num_samples|] Target labels *)
}

(** Configuration parameters for training process *)
type training_config = {
  batch_size: int;             (** Number of samples per batch *)
  learning_rate: float;        (** Step size for gradient descent *)
  num_epochs: int;             (** Number of passes through the training data *)
}

(** Result of client-side training to be sent to server *)
type client_update = {
  model: model;                (** Updated model after local training *)
  num_samples: int;            (** Number of samples used for training *)
  training_loss: float;        (** Final loss achieved during training *)
}

(* === Versioning Types === *)
(** Semantic versioning representation using integers for timestamp
    to avoid floating-point precision issues *)
type version = {
  major: int;                  (** Major version for incompatible API changes *)
  minor: int;                  (** Minor version for backward-compatible functionality *)
  patch: int;                  (** Patch version for backward-compatible bug fixes *)
  timestamp: int;              (** Unix epoch timestamp (seconds since Jan 1, 1970) *)
}

(** Metadata for tracking model provenance and history *)
type model_metadata = {
  version: version;            (** Semantic version of the model *)
  architecture: int array;     (** Network architecture configuration *)
  created_at: int;             (** Creation timestamp (Unix epoch seconds) *)
  updated_at: int;             (** Last update timestamp (Unix epoch seconds) *)
  training_rounds: int;        (** Number of federated training rounds completed *)
  total_clients: int;          (** Cumulative number of clients that contributed *)
}

(** Model with versioning information for lifecycle management *)
type versioned_model = {
  metadata: model_metadata;    (** Version and training history information *)
  model: model;                (** The actual neural network model *)
}

(** Classification of update types for version management *)
type update_type = [
  | `Major  (** Breaking changes, e.g., architecture changes *)
  | `Minor  (** New functionality, e.g., significant learning improvement *)
  | `Patch  (** Bug fixes, minor improvements *)
]

(** Configuration for model integrity checks *)
type integrity_config = {
  max_weight_magnitude: float;   (** Maximum allowed weight/bias magnitude *)
  max_gradient_norm: float;      (** Maximum allowed gradient norm *)
  check_nan_inf: bool;           (** Whether to check for NaN/Inf values *)
  allowed_activations: activation list; (** List of allowed activation functions *)
}

(** Default integrity configuration *)
val default_integrity_config : integrity_config

(* === Core Model Operations === *)
(** Creates a new model with the specified architecture
    @param architecture Array of layer sizes (including input and output layers)
    @return Initialized model with random weights and biases *)
val create_model : int array -> model

(** Performs forward pass through the model
    @param model The neural network model
    @param input Input vector for the model
    @return Array of intermediate activations, with the last element being the output *)
val forward_pass : model -> float array -> float array array

(** Trains a model on client data
    @param model Initial model to train
    @param data Client's local training data
    @param config Training configuration parameters
    @return Client update containing the trained model and statistics *)
val train_client : model -> client_data -> training_config -> client_update

(** Evaluates model performance on a dataset
    @param model Model to evaluate
    @param data Evaluation dataset
    @return Accuracy as a fraction between 0.0 and 1.0 *)
val evaluate_model : model -> client_data -> float

(* === Federated Operations === *)
(** Aggregates updates from multiple clients into a single model
    @param updates List of client updates to aggregate
    @return Aggregated model with weights averaged by sample count *)
val aggregate_updates : client_update list -> model

(** Serializes a model to a string representation for transmission
    @param model Model to serialize
    @return String representation of the model *)
val serialize_model : model -> string

(** Deserializes a model from a string representation
    @param str String representation produced by serialize_model
    @return Reconstructed model *)
val deserialize_model : string -> model

(* === Utility Functions === *)
(** Applies activation function to a single value
    @param activation The activation function to apply
    @param x Input value
    @return Activated value *)
val apply_activation : activation -> float -> float

(** Computes the derivative of an activation function at a point
    @param activation The activation function
    @param x The point at which to compute the derivative
    @return Derivative value *)
val apply_activation_derivative : activation -> float -> float

(** Clips gradients to prevent exploding gradients during training
    
    Scales down gradient matrices if their Frobenius norm exceeds the threshold.
    This preserves the direction but controls the magnitude.
    
    @param gradients Array of gradient matrices to clip
    @param threshold Maximum allowed norm
    @return Clipped gradient matrices *)
val clip_gradients : float array array -> float -> float array array

(** Clips gradients using the max_gradient_norm from integrity config 
    @param gradients Gradients to be clipped
    @param config Integrity configuration containing max_gradient_norm
    @return Clipped gradients *)
val clip_gradients_with_config : float array array -> integrity_config -> float array array

(* === Version Management === *)
(** Creates a new version object
    
    Example:
    ```
    (* Create version 1.0.0 *)
    let v = create_version 1 0 0
    ```
    
    @param major Major version number
    @param minor Minor version number
    @param patch Patch version number
    @return Version object with current timestamp *)
val create_version : int -> int -> int -> version

(** Increments a version according to semantic versioning rules
    
    Example:
    ```
    (* Increment minor version: 1.0.0 -> 1.1.0 *)
    let new_version = increment_version old_version `Minor
    ```
    
    @param version Current version
    @param component Which component to increment
    @return Updated version with new timestamp *)
val increment_version : version -> [`Major | `Minor | `Patch] -> version

(** Converts a version to a string representation
    
    Example:
    ```
    let version_str = version_to_string version  (* e.g. "1.2.3" *)
    ```
    
    @param version Version to convert
    @return String in format "major.minor.patch" *)
val version_to_string : version -> string

(** Compares two versions according to semantic versioning rules
    
    Example:
    ```
    match compare_versions v1 v2 with
    | n when n < 0 -> print_endline "v1 is older than v2"
    | 0 -> print_endline "v1 and v2 are the same version"
    | _ -> print_endline "v1 is newer than v2"
    ```
    
    @param v1 First version
    @param v2 Second version
    @return -1 if v1 < v2, 0 if v1 = v2, 1 if v1 > v2 *)
val compare_versions : version -> version -> int

(* === Model Versioning === *)
(** Creates a new versioned model by combining a model with metadata
    @param model Neural network model
    @param metadata Model metadata including version information
    @return Versioned model *)
val create_versioned_model : model -> model_metadata -> versioned_model

(** Updates the metadata for a model after training
    @param versioned_model Original versioned model
    @param model Updated model after training
    @return New versioned model with updated metadata *)
val update_model_metadata : versioned_model -> model -> versioned_model

(** Checks if two versioned models are compatible for operations
    
    Models are considered compatible if:
    1. They have the same major version
    2. Their architectures are identical
    
    @param model1 First versioned model
    @param model2 Second versioned model
    @return true if compatible, false otherwise *)
val is_compatible_version : versioned_model -> versioned_model -> bool

(* === Secure Aggregation === *)
(** Performs secure aggregation of multiple versioned models
    
    This function combines multiple model updates while providing
    differential privacy guarantees through noise addition.
    
    @param models List of versioned models to aggregate
    @param weights Array of aggregation weights (typically based on sample counts)
    @return Aggregated versioned model with updated metadata *)
val secure_aggregate : versioned_model list -> float array -> versioned_model