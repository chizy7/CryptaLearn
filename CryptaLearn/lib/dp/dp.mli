(** Differential Privacy Interface *)

(* === Basic Types === *)
type privacy_params = {
  epsilon: float;        (* Privacy budget *)
  delta: float;         (* Failure probability *)
  sensitivity: float;   (* L2 sensitivity *)
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
  alpha: float array;    (* Moment orders *)
  log_moments: float array;  (* Log of the moment values *)
  total_queries: int;
  mechanism: noise_mechanism;
}

(* === Privacy Budget Management === *)
val manage_privacy_budget : privacy_params -> query array -> float array * privacy_params

(* === Core Privacy Operations === *)
val create_privacy_params : float -> float -> float -> privacy_params
val create_accountant : noise_mechanism -> privacy_accountant
val add_noise : noise_mechanism -> privacy_params -> float -> float
val add_noise_vector : noise_mechanism -> privacy_params -> float array -> float array

(* === Privacy Accounting === *)
val compute_privacy_spent : privacy_accountant -> float * float
val update_privacy_budget : privacy_accountant -> privacy_params -> privacy_accountant
val check_privacy_budget : privacy_accountant -> privacy_params -> bool

(* === Advanced Composition === *)
val compute_advanced_composition : 
  float ->  (* Target epsilon *)
  float ->  (* Target delta *)
  int ->    (* Number of compositions *)
  float * float  (* Resulting epsilon and delta per iteration *)

val optimal_composition : float -> float -> int -> privacy_params

(* === Gradient Operations === *)
val clip_gradients : float array -> float -> float array
val sanitize_gradients : noise_mechanism -> privacy_params -> float array -> float array

(* === Advanced DP Mechanisms === *)
val create_moments_accountant : noise_mechanism -> float array -> moments_accountant
val compute_rdp : moments_accountant -> float -> float  (* Compute Rényi DP *)
val update_moments : moments_accountant -> privacy_params -> moments_accountant
val convert_rdp_to_dp : float -> float -> float -> float * float

(* === Enhanced Noise Mechanisms === *)
val add_exponential_noise : privacy_params -> float array -> float array
val add_gaussian_noise_adaptive : privacy_params -> float array -> float array
val private_quantile : float array -> float -> privacy_params -> float

(* === Local Differential Privacy === *)
val randomized_response : float -> bool -> bool
val local_dp_mean : float array -> privacy_params -> float
val local_dp_histogram : float array -> int -> privacy_params -> float array

(* === Utility Functions === *)
val estimate_l2_sensitivity : float array array -> float
val compute_optimal_noise_scale : privacy_params -> noise_mechanism -> float
val estimate_sample_complexity : privacy_params -> float -> int
val estimate_privacy_cost : moments_accountant -> float -> float * float