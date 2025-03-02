(* Federated Learning Module *)

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
  architecture: int array;   (* Layer sizes including input and output *)
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
  timestamp: int;  (* Unix epoch in seconds - changed from float to int *)
}

type model_metadata = {
  version: version;
  architecture: int array;
  created_at: int;  (* Unix epoch in seconds - changed from float to int *)
  updated_at: int;  (* Unix epoch in seconds - changed from float to int *)
  training_rounds: int;
  total_clients: int;
}

type versioned_model = {
  metadata: model_metadata;
  model: model;
}

(* === Update Classification === *)
type update_type = [
  | `Major  (* Breaking changes, e.g., architecture changes *)
  | `Minor  (* New functionality, e.g., significant learning improvement *)
  | `Patch  (* Bug fixes, minor improvements *)
]

(* === Activation Functions === *)
let relu x = max 0.0 x
let relu_derivative x = if x > 0.0 then 1.0 else 0.0

let sigmoid x = 
  1.0 /. (1.0 +. exp(-1.0 *. x))
let sigmoid_derivative x =
  let s = sigmoid x in
  s *. (1.0 -. s)

let tanh x = 
  let e_x = exp x in
  let e_minus_x = exp(-1.0 *. x) in
  (e_x -. e_minus_x) /. (e_x +. e_minus_x)
let tanh_derivative x =
  let t = tanh x in
  1.0 -. (t *. t)

let apply_activation act x = match act with
  | ReLU -> relu x
  | Sigmoid -> sigmoid x
  | Tanh -> tanh x

let apply_activation_derivative act x = match act with
  | ReLU -> relu_derivative x
  | Sigmoid -> sigmoid_derivative x
  | Tanh -> tanh_derivative x

(* === Model Creation and Forward Pass === *)
let create_model architecture =
  let layers = Array.make (Array.length architecture - 1) {
    weights = [|[|0.0|]|];
    biases = [|0.0|];
    activation = ReLU;
  } in
  
  for i = 0 to Array.length layers - 1 do
    let input_size = architecture.(i) in
    let output_size = architecture.(i + 1) in
    
    (* Xavier/Glorot initialization *)
    let scale = sqrt(2.0 /. float_of_int(input_size + output_size)) in
    
    let weights = Array.make_matrix input_size output_size 0.0 in
    let biases = Array.make output_size 0.0 in
    
    for j = 0 to input_size - 1 do
      for k = 0 to output_size - 1 do
        weights.(j).(k) <- (Random.float 2.0 -. 1.0) *. scale
      done
    done;
    
    layers.(i) <- {
      weights;
      biases;
      activation = if i = Array.length layers - 1 then Sigmoid else ReLU;
    }
  done;
  
  { layers; architecture }

let forward_pass model input =
  let activations = Array.make (Array.length model.layers + 1) [||] in
  activations.(0) <- input;
  
  for i = 0 to Array.length model.layers - 1 do
    let layer = model.layers.(i) in
    let prev_activation = activations.(i) in
    let curr_size = Array.length layer.biases in
    let curr_activation = Array.make curr_size 0.0 in
    
    (* Compute linear combination *)
    for j = 0 to curr_size - 1 do
      curr_activation.(j) <- layer.biases.(j);
      for k = 0 to Array.length prev_activation - 1 do
        curr_activation.(j) <- curr_activation.(j) +. 
          prev_activation.(k) *. layer.weights.(k).(j)
      done;
      curr_activation.(j) <- apply_activation layer.activation curr_activation.(j)
    done;
    
    activations.(i + 1) <- curr_activation
  done;
  
  activations

(* === Training Implementation === *)
let backward_pass model activations target learning_rate =
  let num_layers = Array.length model.layers in
  let deltas = Array.make num_layers [||] in
  
  (* Compute output layer error *)
  let output_layer = num_layers - 1 in
  let output_deltas = Array.make (Array.length model.layers.(output_layer).biases) 0.0 in
  
  for i = 0 to Array.length output_deltas - 1 do
    let predicted = activations.(num_layers).(i) in
    let error = predicted -. target.(i) in
    let activation_derivative = 
      apply_activation_derivative 
        model.layers.(output_layer).activation 
        (predicted) in
    output_deltas.(i) <- error *. activation_derivative
  done;
  deltas.(output_layer) <- output_deltas;
  
  (* Backpropagate error *)
  for l = output_layer - 1 downto 0 do
    let layer = model.layers.(l) in
    let next_layer = model.layers.(l + 1) in
    let layer_deltas = Array.make (Array.length layer.biases) 0.0 in
    
    for i = 0 to Array.length layer_deltas - 1 do
      let error = 0.0 in
      let error = ref error in
      for j = 0 to Array.length next_layer.biases - 1 do
        error := !error +. deltas.(l + 1).(j) *. next_layer.weights.(i).(j)
      done;
      
      let activation_derivative = 
        apply_activation_derivative 
          layer.activation 
          activations.(l + 1).(i) in
      layer_deltas.(i) <- !error *. activation_derivative
    done;
    deltas.(l) <- layer_deltas
  done;
  
  (* Update weights and biases *)
  for l = 0 to num_layers - 1 do
    let layer = model.layers.(l) in
    
    (* Update biases *)
    for i = 0 to Array.length layer.biases - 1 do
      layer.biases.(i) <- layer.biases.(i) -. learning_rate *. deltas.(l).(i)
    done;
    
    (* Update weights *)
    for i = 0 to Array.length layer.weights - 1 do
      for j = 0 to Array.length layer.weights.(i) - 1 do
        layer.weights.(i).(j) <- layer.weights.(i).(j) -. 
          learning_rate *. activations.(l).(i) *. deltas.(l).(j)
      done
    done
  done;
  
  model

let train_client model data config =
  let num_samples = Array.length data.features in
  let num_batches = (num_samples + config.batch_size - 1) / config.batch_size in
  
  let total_loss = ref 0.0 in
  let model_ref = ref model in
  
  for _epoch = 1 to config.num_epochs do
    (* Shuffle data *)
    let indices = Array.init num_samples (fun i -> i) in
    for i = num_samples - 1 downto 1 do
      let j = Random.int (i + 1) in
      let temp = indices.(i) in
      indices.(i) <- indices.(j);
      indices.(j) <- temp
    done;
    
    for batch = 0 to num_batches - 1 do
      let start_idx = batch * config.batch_size in
      let end_idx = min (start_idx + config.batch_size) num_samples in
      let batch_size = end_idx - start_idx in
      
      (* Create batch *)
      let batch_features = Array.make batch_size [||] in
      let batch_labels = Array.make batch_size 0.0 in
      for i = 0 to batch_size - 1 do
        let idx = indices.(start_idx + i) in
        batch_features.(i) <- data.features.(idx);
        batch_labels.(i) <- data.labels.(idx)
      done;
      
      (* Process each sample in batch *)
      for i = 0 to batch_size - 1 do
        let activations = forward_pass !model_ref batch_features.(i) in
        model_ref := backward_pass !model_ref activations [|batch_labels.(i)|] config.learning_rate;
        
        (* Compute loss (MSE) *)
        let output = Array.length activations - 1 in
        let error = activations.(output).(0) -. batch_labels.(i) in
        total_loss := !total_loss +. (error *. error)
      done
    done
  done;
  
  {
    model = !model_ref;
    num_samples;
    training_loss = !total_loss /. float_of_int (num_samples * config.num_epochs)
  }

(* === Model Evaluation === *)
let evaluate_model model data =
  let num_samples = Array.length data.features in
  let correct = ref 0 in
  
  for i = 0 to num_samples - 1 do
    let activations = forward_pass model data.features.(i) in
    let prediction = activations.(Array.length activations - 1).(0) in
    if abs_float (prediction -. data.labels.(i)) < 0.5 then
      incr correct
  done;
  
  float_of_int !correct /. float_of_int num_samples

(* === Federated Operations === *)
let aggregate_updates updates =
  match updates with
  | [] -> failwith "No updates to aggregate"
  | first :: _ ->
      let total_samples = List.fold_left (fun acc u -> acc + u.num_samples) 0 updates in
      let base_model = first.model in
      let aggregated = create_model base_model.architecture in
      
      List.iter (fun update ->
        let weight = float_of_int update.num_samples /. float_of_int total_samples in
        Array.iteri (fun i layer ->
          let update_layer = update.model.layers.(i) in
          (* Aggregate weights *)
          Array.iteri (fun j row ->
            Array.iteri (fun k _ ->
              aggregated.layers.(i).weights.(j).(k) <-
                aggregated.layers.(i).weights.(j).(k) +. weight *. update_layer.weights.(j).(k)
            ) row
          ) layer.weights;
          (* Aggregate biases *)
          Array.iteri (fun j _ ->
            aggregated.layers.(i).biases.(j) <-
              aggregated.layers.(i).biases.(j) +. weight *. update_layer.biases.(j)
          ) layer.biases
        ) base_model.layers
      ) updates;
      aggregated

(* === Model Serialization === *)
let serialize_model model =
  let serialize_layer layer =
    let weights_str = Array.map (Array.map string_of_float) layer.weights
                     |> Array.map (Array.to_list)
                     |> Array.to_list
                     |> List.map (String.concat ",")
                     |> String.concat ";" in
    let biases_str = Array.map string_of_float layer.biases
                    |> Array.to_list
                    |> String.concat "," in
    let act_str = match layer.activation with
      | ReLU -> "relu"
      | Sigmoid -> "sigmoid"
      | Tanh -> "tanh" in
    Printf.sprintf "%s|%s|%s" weights_str biases_str act_str
  in
  let layers_str = Array.map serialize_layer model.layers
                   |> Array.to_list
                   |> String.concat "##" in
  let arch_str = Array.map string_of_int model.architecture
                 |> Array.to_list
                 |> String.concat "," in
  Printf.sprintf "%s@@%s" layers_str arch_str

let deserialize_model str =
  let parse_activation = function
    | "relu" -> ReLU
    | "sigmoid" -> Sigmoid
    | "tanh" -> Tanh
    | _ -> failwith "Invalid activation function" in

  match String.split_on_char '@' str with
  | [layers_str; arch_str] ->
      let architecture = Array.of_list (List.map int_of_string (String.split_on_char ',' arch_str)) in
      let layers = Array.of_list (
        List.map (fun layer_str ->
          match String.split_on_char '|' layer_str with
          | [weights_str; biases_str; act_str] ->
              let weights = Array.of_list (
                List.map (fun row_str ->
                  Array.of_list (List.map float_of_string (String.split_on_char ',' row_str))
                ) (String.split_on_char ';' weights_str)
              ) in
              let biases = Array.of_list (List.map float_of_string (String.split_on_char ',' biases_str)) in
              let activation = parse_activation act_str in
              { weights; biases; activation }
          | _ -> failwith "Invalid layer format"
        ) (String.split_on_char '#' layers_str)
      ) in
      { layers; architecture }
  | _ -> failwith "Invalid model format"

(* === Gradient Operations === *)
let clip_gradients gradients clip_norm =
  let norm = sqrt (Array.fold_left (fun acc row ->
    acc +. Array.fold_left (fun acc' x -> acc' +. x *. x) 0.0 row
  ) 0.0 gradients) in
  if norm > clip_norm then
    Array.map (Array.map (fun x -> x *. clip_norm /. norm)) gradients
  else
    gradients

(* Configurable integrity checker *)
type integrity_config = {
  max_weight_magnitude: float;   (* Maximum allowed weight/bias magnitude *)
  max_gradient_norm: float;      (* Maximum allowed gradient norm *)
  check_nan_inf: bool;           (* Whether to check for NaN/Inf values *)
  allowed_activations: activation list; (* List of allowed activation functions *)
}

let default_integrity_config = {
  max_weight_magnitude = 100.0;
  max_gradient_norm = 10.0;
  check_nan_inf = true;
  allowed_activations = [ReLU; Sigmoid; Tanh];
}

let clip_gradients_with_config gradients config =
  clip_gradients gradients config.max_gradient_norm

(* === Version Management === *)
let create_version major minor patch =
  { major; minor; patch; timestamp = int_of_float (Unix.time ()) }

let increment_version version = function
  | `Major -> { major = version.major + 1; minor = 0; patch = 0; timestamp = int_of_float (Unix.time ()) }
  | `Minor -> { version with minor = version.minor + 1; patch = 0; timestamp = int_of_float (Unix.time ()) }
  | `Patch -> { version with patch = version.patch + 1; timestamp = int_of_float (Unix.time ()) }

(* === Version String Operations === *)
let version_to_string version =
  Printf.sprintf "%d.%d.%d" version.major version.minor version.patch

let compare_versions v1 v2 =
  match compare v1.major v2.major with
  | 0 -> (match compare v1.minor v2.minor with
          | 0 -> compare v1.patch v2.patch
          | c -> c)
  | c -> c

(* === Model Versioning === *)
let create_versioned_model model metadata =
  { metadata; model }

(* Determine update type based on model changes *)
let determine_update_type (old_model:model) (new_model:model) =
  (* Check for architecture changes (major update) *)
  if Array.length old_model.architecture != Array.length new_model.architecture then
    `Major
  else if not (Array.for_all2 (=) old_model.architecture new_model.architecture) then
    `Major
  (* Check for significant changes in weights (could indicate minor improvement) *)
  else
    let weight_diff_ratio = ref 0.0 in
    let total_weights = ref 0 in
    
    for i = 0 to Array.length old_model.layers - 1 do
      let old_layer = old_model.layers.(i) in
      let new_layer = new_model.layers.(i) in
      
      for j = 0 to Array.length old_layer.weights - 1 do
        for k = 0 to Array.length old_layer.weights.(j) - 1 do
          weight_diff_ratio := !weight_diff_ratio +. 
                             abs_float (new_layer.weights.(j).(k) -. old_layer.weights.(j).(k));
          total_weights := !total_weights + 1;
        done
      done;
      
      for j = 0 to Array.length old_layer.biases - 1 do
        weight_diff_ratio := !weight_diff_ratio +. 
                           abs_float (new_layer.biases.(j) -. old_layer.biases.(j));
        total_weights := !total_weights + 1;
      done
    done;
    
    let avg_change = !weight_diff_ratio /. float_of_int !total_weights in
    
    (* Threshold for considering a minor vs patch update *)
    if avg_change > 0.1 then  (* Significant changes, more than 10% average weight change *)
      `Minor
    else
      `Patch

let update_model_metadata versioned_model new_model =
  (* Determine update type based on model changes *)
  let update_type = determine_update_type versioned_model.model new_model in
  
  let metadata = {
    versioned_model.metadata with
    version = increment_version versioned_model.metadata.version update_type;
    updated_at = int_of_float (Unix.time ());
    training_rounds = versioned_model.metadata.training_rounds + 1;
  } in
  { metadata; model = new_model }

let is_compatible_version vm1 vm2 =
  vm1.metadata.version.major = vm2.metadata.version.major &&
  Array.length vm1.metadata.architecture = Array.length vm2.metadata.architecture &&
  Array.for_all2 (=) vm1.metadata.architecture vm2.metadata.architecture

(* === Model Integrity === *)
let verify_model_integrity ?(config=default_integrity_config) (model:model) =
  let check_layer layer =
    (* Check weight magnitudes *)
    let weights_ok = Array.for_all (fun row ->
      Array.for_all (fun w -> 
        abs_float w < config.max_weight_magnitude &&
        (not config.check_nan_inf || (not (Float.is_nan w) && not (Float.is_infinite w)))
      ) row
    ) layer.weights in
    
    (* Check bias magnitudes *)
    let biases_ok = Array.for_all (fun b -> 
      abs_float b < config.max_weight_magnitude &&
      (not config.check_nan_inf || (not (Float.is_nan b) && not (Float.is_infinite b)))
    ) layer.biases in
    
    (* Check activation function *)
    let activation_ok = List.mem layer.activation config.allowed_activations in
    
    weights_ok && biases_ok && activation_ok
  in
  
  (* Check architecture sanity *)
  let architecture_ok = 
    Array.length model.architecture >= 2 && (* At least input and output layer *)
    Array.for_all (fun size -> size > 0) model.architecture &&
    Array.length model.layers = Array.length model.architecture - 1
  in
  
  architecture_ok && Array.for_all check_layer model.layers

(* === Secure Aggregation Result Type === *)
let secure_aggregate models weights =
  (* Validate inputs *)
  if List.length models = 0 then
    failwith "No models to aggregate";
  
  let base = List.hd models in
  let compatibility_check = 
    List.for_all (fun m -> is_compatible_version base m) (List.tl models) in
  
  if not compatibility_check then
    failwith "Incompatible model versions";
  
  let total_weight = Array.fold_left (+.) 0.0 weights in
  if abs_float (total_weight -. 1.0) > 1e-6 then
    failwith "Weights must sum to 1.0";
  
  (* Verify integrity of all models *)
  let integrity_config = {
    default_integrity_config with
    (* Slightly more permissive for aggregation *)
    max_weight_magnitude = 150.0;
  } in
  
  let integrity_check =
    List.for_all (fun m -> verify_model_integrity ~config:integrity_config m.model) models in
  
  if not integrity_check then
    failwith "Model integrity check failed";
  
  (* Common aggregation function for reuse *)
  let perform_aggregation models weights =
    let base_model = (List.hd models).model in
    let aggregated = create_model base_model.architecture in
    
    List.iteri (fun i vm ->
      let weight = weights.(i) in
      Array.iteri (fun layer_idx layer ->
        Array.iteri (fun j row ->
          Array.iteri (fun k w ->
            aggregated.layers.(layer_idx).weights.(j).(k) <-
              aggregated.layers.(layer_idx).weights.(j).(k) +. weight *. w
          ) row
        ) layer.weights;
        Array.iteri (fun j b ->
          aggregated.layers.(layer_idx).biases.(j) <-
            aggregated.layers.(layer_idx).biases.(j) +. weight *. b
        ) layer.biases
      ) vm.model.layers
    ) models;
    
    aggregated
  in
  
  (* Update metadata for the new aggregated model *)
  let aggregated_model = perform_aggregation models weights in
  
  (* Determine if this is a minor or patch update based on changes *)
  let base_model = (List.hd models).model in
  let update_type = determine_update_type base_model aggregated_model in
  
  let new_metadata = {
    base.metadata with
    version = increment_version base.metadata.version 
              (if update_type = `Patch then `Minor else update_type);
    updated_at = int_of_float (Unix.time ());
    training_rounds = base.metadata.training_rounds + 1;
    total_clients = base.metadata.total_clients + List.length (List.tl models);
  } in
  
  (* Final integrity check on aggregated model *)
  if verify_model_integrity aggregated_model then
    create_versioned_model aggregated_model new_metadata
  else
    failwith "Aggregated model failed integrity check"
