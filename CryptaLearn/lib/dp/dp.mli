(** Differential Privacy Functions *)

type privacy_params = {
  epsilon: float;        (* Privacy budget *)
  delta: float;         (* Failure probability *)
  sensitivity: float;   (* L2 sensitivity *)
}

type noise_mechanism = 
  | Laplace
  | Gaussian

type privacy_accountant = {
  total_epsilon: float;
  total_delta: float;
  queries: int;
  mechanism: noise_mechanism;
}

(* Core privacy operations *)
val create_privacy_params : float -> float -> float -> privacy_params
val create_accountant : noise_mechanism -> privacy_accountant
val add_noise : noise_mechanism -> privacy_params -> float -> float
val add_noise_vector : noise_mechanism -> privacy_params -> float array -> float array

(* Gradient operations *)
val clip_gradients : float array -> float -> float array
val sanitize_gradients : noise_mechanism -> privacy_params -> float array -> float array

(* Privacy accounting *)
val compute_privacy_spent : privacy_accountant -> float * float
val update_privacy_budget : privacy_accountant -> privacy_params -> privacy_accountant
val check_privacy_budget : privacy_accountant -> privacy_params -> bool

(* Advanced composition *)
val compute_advanced_composition : 
  float ->  (* Target epsilon *)
  float ->  (* Target delta *)
  int ->    (* Number of compositions *)
  float * float  (* Resulting epsilon and delta per iteration *)

(* Utility calculations *)
val estimate_l2_sensitivity : float array array -> float
val compute_optimal_noise_scale : privacy_params -> noise_mechanism -> float
val estimate_sample_complexity : privacy_params -> float -> int
