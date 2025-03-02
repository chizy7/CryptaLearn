(** Differential Privacy Interface 
    This module provides a comprehensive set of tools for implementing differential privacy
    in machine learning and data analysis applications. *)

(* === Basic Types === *)
type privacy_params = {
  epsilon: float;       (** Privacy budget controlling privacy-utility tradeoff *)
  delta: float;         (** Failure probability - should be < 1/n where n is dataset size *)
  sensitivity: float;   (** L2 sensitivity - maximum change in function output from adding/removing one record *)
}

(** Query structure mirrors the fields in privacy_params. When using this type, ensure
    that the epsilon, delta, and sensitivity values align with the corresponding
    privacy_params fields to maintain consistent privacy guarantees. *)
type query = {
  value: float;         (** The query value to be protected *)
  epsilon: float;       (** The privacy budget for this specific query *)
  delta: float;         (** Failure probability for this specific query *)
  sensitivity: float;   (** L2 sensitivity for this specific query *)
}

(** Available noise mechanisms for achieving differential privacy *)
type noise_mechanism = 
  | Laplace     (** For epsilon-DP with L1 sensitivity *)
  | Gaussian    (** For (epsilon,delta)-DP with L2 sensitivity *)
  | Exponential (** For exponential mechanism with utility scores *)

(* === Privacy Accounting Types === *)
type privacy_accountant = {
  total_epsilon: float;  (** Cumulative privacy budget spent *)
  total_delta: float;    (** Cumulative failure probability *)
  queries: int;          (** Number of queries processed *)
  mechanism: noise_mechanism; (** Noise mechanism being used *)
}

(** Rényi Differential Privacy (RDP) accounting structure *)
type moments_accountant = {
  alpha: float array;    (** Moment orders (α values) for RDP accounting. Typically range from 2 to 64. *)
  log_moments: float array;  (** Log of the moment values at each α. Used to track privacy expenditure. *)
  total_queries: int;    (** Number of queries processed with this accountant *)
  mechanism: noise_mechanism; (** The noise mechanism being used *)
}

(* === Privacy Budget Management === *)
(** Manages privacy budget allocation across multiple queries.
    Note: This function is not thread-safe. If used in a concurrent context, 
    external synchronization is required to prevent race conditions.
    @param params Privacy parameters for the entire operation
    @param queries Array of queries to be processed
    @return Array of noisy query responses and updated privacy parameters *)
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

(** Computes the optimal privacy parameters for composed mechanisms.
    
    Example usage:
    ```
    (* For 100 iterations with target ε=1.0, δ=1e-6 *)
    let params = optimal_composition 1.0 1e-6 100
    ```
    
    @param target_epsilon Overall privacy budget target
    @param target_delta Overall failure probability target
    @param iterations Number of compositions
    @return Optimized privacy parameters for each iteration *)
val optimal_composition : float -> float -> int -> privacy_params

(* === Gradient Operations === *)
(** Clips gradient values to control sensitivity.
    @param gradients Array of gradient values
    @param threshold Maximum L2 norm threshold
    @return Clipped gradient array with the same direction but controlled magnitude *)
val clip_gradients : float array -> float -> float array

(** Sanitizes gradients using a specified noise mechanism.
    Internally applies clipping followed by noise addition.
    @param mechanism Noise mechanism to use (typically Gaussian for gradients)
    @param params Privacy parameters including sensitivity (often set to the clip threshold)
    @param gradients Array of gradient values
    @return Privacy-preserving gradient array *)
val sanitize_gradients : noise_mechanism -> privacy_params -> float array -> float array

(* === Advanced DP Mechanisms === *)
(** Creates a moments accountant for tracking privacy using Rényi DP.
    See: Abadi et al. "Deep Learning with Differential Privacy" (2016)
    https://arxiv.org/abs/1607.00133
    
    @param mechanism Noise mechanism to track
    @param alpha_values Array of moment orders to track (typically [2.;4.;8.;16.;32.;64.])
    @return Initialized moments accountant *)
val create_moments_accountant : noise_mechanism -> float array -> moments_accountant

(** Computes Rényi differential privacy at a specified alpha value.
    Used for converting between RDP and (ε,δ)-DP.
    
    @param accountant The moments accountant containing tracking information
    @param alpha The order at which to evaluate RDP
    @return The RDP value at the specified alpha *)
val compute_rdp : moments_accountant -> float -> float

val update_moments : moments_accountant -> privacy_params -> moments_accountant

(** Converts Rényi DP to approximate DP guarantees.
    Based on the conversion theorem in:
    Mironov, "Rényi Differential Privacy" (2017)
    https://arxiv.org/abs/1702.07476
    
    @param alpha The RDP order parameter
    @param epsilon_rdp The RDP epsilon at order alpha
    @param delta The target failure probability
    @return A tuple of (epsilon, delta) in the approximate DP framework *)
val convert_rdp_to_dp : float -> float -> float -> float * float

(* === Enhanced Noise Mechanisms === *)
(** Adds noise from the exponential mechanism.
    Useful for selecting discrete options with differential privacy.
    
    @param params Privacy parameters
    @param utility_scores Array of utility scores for each option
    @return Array with exponential noise added *)
val add_exponential_noise : privacy_params -> float array -> float array

(** Adds Gaussian noise with adaptive scaling based on data values.
    Adjusts noise level based on the distribution of values.
    
    @param params Privacy parameters
    @param values Array of values to be protected
    @return Array with adaptive Gaussian noise added *)
val add_gaussian_noise_adaptive : privacy_params -> float array -> float array

(** Computes a private quantile (e.g., median) from data.
    Uses the exponential mechanism to select a private quantile.
    
    @param data Array of data points
    @param quantile The desired quantile (0.5 for median)
    @param params Privacy parameters
    @return The private quantile value *)
val private_quantile : float array -> float -> privacy_params -> float

(* === Local Differential Privacy === *)
(** Implements randomized response for private boolean values.
    
    Example usage:
    ```
    (* For ε=3.0, probability of flipping is about 0.0474 *)
    let p_flip = 1.0 /. (1.0 +. exp epsilon)
    let private_answer = randomized_response epsilon true
    ```
    
    @param epsilon Privacy parameter
    @param value Original boolean value
    @return Privatized boolean value *)
val randomized_response : float -> bool -> bool

(** Computes a private mean using local differential privacy.
    
    Example usage:
    ```
    let private_mean = local_dp_mean [|1.2; 3.4; 2.1; 5.6|] {epsilon=1.0; delta=0.0; sensitivity=1.0}
    ```
    
    @param data Array of values
    @param params Privacy parameters
    @return Private estimate of the mean *)
val local_dp_mean : float array -> privacy_params -> float

(** Computes a private histogram using local differential privacy.
    
    Example usage:
    ```
    (* For 10 bins over data in range [0,1] *)
    let private_hist = local_dp_histogram data 10 {epsilon=2.0; delta=0.0; sensitivity=1.0}
    ```
    
    @param data Array of values to histogram
    @param bins Number of histogram bins
    @param params Privacy parameters
    @return Array of private bin counts *)
val local_dp_histogram : float array -> int -> privacy_params -> float array

(* === Utility Functions === *)
val estimate_l2_sensitivity : float array array -> float
val compute_optimal_noise_scale : privacy_params -> noise_mechanism -> float
val estimate_sample_complexity : privacy_params -> float -> int

(** Estimates the privacy cost (epsilon, delta) for a given set of moments.
    
    @param accountant The moments accountant with tracking information
    @param target_delta The target delta value
    @return A tuple of (epsilon, delta) representing the privacy cost,
            where epsilon is the computed value that satisfies the target delta *)
val estimate_privacy_cost : moments_accountant -> float -> float * float