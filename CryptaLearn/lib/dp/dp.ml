[@@@ocaml.warning "-32"]  (* Suppress unused value warnings *)

(** Differential Privacy Module *)

(* === Basic Types === *)
type privacy_params = {
  epsilon: float;      (* Privacy budget *)
  delta: float;       (* Failure probability *)
  sensitivity: float; (* L2 sensitivity *)
}

type query = {
  value: float;
  epsilon: float;
  delta: float;
  sensitivity: float;
}

type noise_mechanism = 
  | Laplace
  | Gaussian
  | Exponential

(* === Privacy Accounting Types === *)
type privacy_accountant = {
  total_epsilon: float;
  total_delta: float;
  queries: int;
  mechanism: noise_mechanism;
}

type moments_accountant = {
  alpha: float array;
  log_moments: float array;
  total_queries: int;
  mechanism: noise_mechanism;
}

(* === Noise Generation Utilities === *)
let sample_laplace scale =
  let u = Random.float 1.0 -. 0.5 in
  let sign = if u >= 0.0 then 1.0 else -1.0 in
  -. scale *. sign *. log(1.0 -. 2.0 *. abs_float u)

let sample_gaussian mean std =
  let u1 = Random.float 1.0 in
  let u2 = Random.float 1.0 in
  mean +. std *. sqrt(-2.0 *. log u1) *. cos(2.0 *. Float.pi *. u2)

(* === Core Privacy Operations === *)
let create_privacy_params epsilon delta sensitivity =
  { epsilon; delta; sensitivity }

let create_accountant mechanism =
  { total_epsilon = 0.0; total_delta = 0.0; queries = 0; mechanism }

let compute_noise_scale (params: privacy_params) mechanism =
  match mechanism with
  | Laplace -> params.sensitivity /. params.epsilon
  | Gaussian -> 
      let c = sqrt(2.0 *. log(1.25 /. params.delta)) in
      params.sensitivity *. c /. params.epsilon
  | Exponential -> params.sensitivity /. params.epsilon

let add_noise mechanism (params: privacy_params) value =
  let scale = compute_noise_scale params mechanism in
  match mechanism with
  | Laplace -> value +. sample_laplace scale
  | Gaussian -> value +. sample_gaussian 0.0 scale
  | Exponential -> 
      let noise = -. scale *. log(1.0 -. Random.float 1.0) in
      if Random.bool () then value +. noise else value -. noise

let add_noise_vector mechanism (params: privacy_params) values =
  Array.map (add_noise mechanism params) values

(* === Gradient Operations === *)
let clip_gradients gradients clip_norm =
  let norm = sqrt (Array.fold_left (fun acc x -> acc +. x *. x) 0.0 gradients) in
  if norm > clip_norm then
    Array.map (fun x -> x *. clip_norm /. norm) gradients
  else
    gradients

let sanitize_gradients mechanism (params: privacy_params) gradients =
  let clipped = clip_gradients gradients params.sensitivity in
  add_noise_vector mechanism params clipped

(* === Privacy Accounting === *)
let compute_privacy_spent = function
  | { total_epsilon; mechanism = Laplace; _ } -> 
      (total_epsilon, 0.0)  (* Laplace has no delta *)
  | { total_epsilon; total_delta; queries; mechanism = Gaussian; _ } ->
      let eps = total_epsilon *. 
        sqrt(2.0 *. float_of_int queries *. 
             log(1.0 /. total_delta)) in
      (eps, total_delta)
  | { total_epsilon; total_delta; mechanism = Exponential; _ } ->
      (total_epsilon, total_delta)

let update_privacy_budget accountant (params: privacy_params) =
  { accountant with
    total_epsilon = accountant.total_epsilon +. params.epsilon;
    total_delta = accountant.total_delta +. params.delta;
    queries = accountant.queries + 1;
  }

let check_privacy_budget accountant (params: privacy_params) =
  let eps, delta = compute_privacy_spent accountant in
  eps <= params.epsilon && delta <= params.delta

(* === Advanced Composition === *)
let compute_advanced_composition target_epsilon target_delta num_compositions =
  let epsilon_prime = target_epsilon /. 
    sqrt(2.0 *. float_of_int num_compositions *. log(1.0 /. target_delta)) in
  let delta_prime = target_delta /. float_of_int num_compositions in
  (epsilon_prime, delta_prime)

let optimal_composition target_epsilon target_delta num_compositions =
  let single_epsilon = target_epsilon /. 
    sqrt (2.0 *. float_of_int num_compositions *. log (1.0 /. target_delta)) in
  let single_delta = target_delta /. float_of_int num_compositions in
  { epsilon = single_epsilon; delta = single_delta; sensitivity = 1.0 }

(* === Advanced DP Mechanisms === *)
let create_moments_accountant mechanism orders =
  {
    alpha = orders;
    log_moments = Array.make (Array.length orders) 0.0;
    total_queries = 0;
    mechanism;
  }

let compute_rdp accountant q =
  let compute_moment alpha =
    match accountant.mechanism with
    | Gaussian ->
        let sigma = 1.0 in  (* normalized noise scale *)
        alpha *. q *. q /. (2.0 *. sigma *. sigma)
    | Laplace ->
        let lambda = 1.0 in  (* normalized noise scale *)
        log (alpha /. (2.0 *. lambda -. 1.0)) +. alpha *. q *. q
    | Exponential ->
        alpha *. q *. (exp 1.0 -. 1.0)
  in
  Array.fold_left (fun acc alpha -> acc +. compute_moment alpha) 0.0 accountant.alpha

let update_moments accountant (params: privacy_params) =
  let new_log_moments = Array.map2 
    (fun _ old_moment -> 
        old_moment +. compute_rdp accountant (params.epsilon /. params.sensitivity))
    accountant.alpha
    accountant.log_moments
  in
  { accountant with 
    log_moments = new_log_moments;
    total_queries = accountant.total_queries + 1 
  }

let convert_rdp_to_dp alpha epsilon delta =
  let rdp_epsilon = epsilon +. log (1.0 /. delta) /. (alpha -. 1.0) in
  (rdp_epsilon, delta)

(* === Enhanced Noise Mechanisms === *)
let add_exponential_noise (params: privacy_params) data =
  let scale = params.sensitivity /. params.epsilon in
  Array.map (fun x ->
    let u = Random.float 1.0 in
    let noise = -. scale *. log (1.0 -. u) in
    if Random.bool () then x +. noise else x -. noise
  ) data

let add_gaussian_noise_adaptive (params: privacy_params) data =
  let adaptive_scale factor =
    params.sensitivity *. sqrt (2.0 *. log (1.25 /. params.delta)) /. 
    (params.epsilon *. factor)
  in
  Array.mapi (fun i x ->
    let scale = adaptive_scale (float_of_int (i + 1)) in
    x +. sample_gaussian 0.0 scale
  ) data

let private_quantile data p (params: privacy_params) =
  let n = Array.length data in
  let sorted = Array.copy data in
  Array.sort compare sorted;
  let index = int_of_float (p *. float_of_int n) in
  let noise = sample_laplace (params.sensitivity /. params.epsilon) in
  sorted.(index) +. noise

(* === Local Differential Privacy === *)
let randomized_response epsilon input =
  let p = exp epsilon /. (1.0 +. exp epsilon) in
  if input then Random.float 1.0 < p
  else Random.float 1.0 < (1.0 -. p)

let local_dp_mean data (params: privacy_params) =
  let n = Array.length data in
  let noisy_sum = Array.fold_left (fun acc x ->
    let noisy_x = x +. sample_laplace (params.sensitivity /. params.epsilon) in
    acc +. noisy_x
  ) 0.0 data in
  noisy_sum /. float_of_int n

let local_dp_histogram data bins (params: privacy_params) =
  let hist = Array.make bins 0.0 in
  let bin_size = 1.0 /. float_of_int bins in
  Array.iter (fun x ->
    let bin_idx = min (int_of_float (x /. bin_size)) (bins - 1) in
    hist.(bin_idx) <- hist.(bin_idx) +. 1.0
  ) data;
  Array.map (fun count ->
    count +. sample_laplace (2.0 /. params.epsilon)
  ) hist

(* === Budget Management === *)
let manage_privacy_budget (initial_budget: privacy_params) queries =
  let remaining_budget = ref initial_budget in
  let results = Array.make (Array.length queries) 0.0 in
  Array.iteri (fun i query ->
    if !remaining_budget.epsilon <= 0.0 then
      results.(i) <- 0.0
    else begin
      let new_params : privacy_params = {
        epsilon = min query.epsilon !remaining_budget.epsilon;
        delta = query.delta;
        sensitivity = query.sensitivity;
      } in
      let noise = add_noise Gaussian new_params 0.0 in
      results.(i) <- query.value +. noise;
      remaining_budget := {
        !remaining_budget with
        epsilon = !remaining_budget.epsilon -. new_params.epsilon
      }
    end
  ) queries;
  (results, !remaining_budget)

(* === Utility Functions === *) 
(* Not currently using this func - used for testing and might use it later on - for now, just suppressed  to avoid errors *)
let log_comb n k =
  let rec aux n k acc =
    if k = 0 then acc
    else aux (n-1) (k-1) (acc +. log (float_of_int n) -. log (float_of_int k))
  in aux n k 0.0

let estimate_l2_sensitivity gradients =
  let max_norm = ref 0.0 in
  Array.iter (fun grad_vector ->
    let norm = sqrt (Array.fold_left (fun acc x -> acc +. x *. x) 0.0 grad_vector) in
    max_norm := max !max_norm norm
  ) gradients;
  !max_norm

let compute_optimal_noise_scale (params: privacy_params) mechanism =
  match mechanism with
  | Laplace -> 
      params.sensitivity *. log(1.0 /. params.delta) /. params.epsilon
  | Gaussian | Exponential ->
      params.sensitivity *. sqrt(2.0 *. log(1.25 /. params.delta)) /. params.epsilon

let estimate_sample_complexity (params: privacy_params) target_accuracy =
  let scale = compute_optimal_noise_scale params Gaussian in
  int_of_float (ceil (scale *. scale /. (target_accuracy *. target_accuracy)))

let estimate_privacy_cost accountant confidence_level =
  let max_moment = Array.fold_left max 0.0 accountant.log_moments in
  let effective_epsilon = max_moment *. sqrt (2.0 *. log (1.0 /. confidence_level)) in
  let effective_delta = confidence_level in
  (effective_epsilon, effective_delta)

(* Not currently using this func - used for testing and might use it later on - for now, just suppressed  to avoid errors *)
let adaptive_privacy_allocation total_epsilon _num_queries query_importance =
  let total_importance = Array.fold_left (+.) 0.0 query_importance in
  Array.map (fun importance ->
    importance *. total_epsilon /. total_importance
  ) query_importance