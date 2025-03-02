(** Homomorphic Encryption Interface 
    This module provides a Paillier cryptosystem implementation supporting homomorphic
    operations on encrypted data. *)

(* === Key Module Types === *)
module type PublicKey = sig
  val n : Z.t         (* RSA modulus *)
  val g : Z.t         (* Generator *)
  val n_square : Z.t  (* n^2, precomputed *)
  val bits : int      (* Key size in bits *)
end

module type PrivateKey = sig
  val lambda : Z.t    (* LCM of (p-1) and (q-1) *)
  val mu : Z.t        (* Modular multiplicative inverse *)
  val p : Z.t         (* First prime factor *)
  val q : Z.t         (* Second prime factor *)
end

(* === Basic Types === *)
type public_key = (module PublicKey)
type private_key = (module PrivateKey)
type ciphertext = Z.t
type plaintext = Z.t

(** Matrix representation for homomorphic operations.
    
    Performance note: Matrix operations can be memory-intensive for large datasets.
    Consider chunking large matrices (>1000×1000) to avoid excessive memory usage.
    Time complexity for most operations scales as O(rows × cols).
    
    For very large datasets (>10,000 elements), consider using sparse representations
    or chunked processing to manage memory consumption. *)
type matrix = {
  rows: int;
  cols: int;
  data: ciphertext array array;
}

(* === Key Rotation Interface === *)
(** KeyRotation module type for managing key lifecycle.
    
    Recommended rotation intervals:
    - For standard applications: 30-90 days (2,592,000-7,776,000 seconds)
    - For high-security applications: 7-30 days (604,800-2,592,000 seconds)
    - For development/testing: Any shorter interval is acceptable
    
    Key rotation should be scheduled during low-usage periods to minimize
    impact on system performance. After rotation, previously encrypted data
    should be re-encrypted with the new key when possible. *)
module type KeyRotation = sig
  val rotation_period : int  (* in seconds *)
  val key_bits : int
  val current_key : unit -> (module PublicKey) * (module PrivateKey)
  val rotate_keys : unit -> (module PublicKey) * (module PrivateKey)
  val last_rotation : unit -> float
end

(* === Core Encryption Operations === *)
val generate_keypair : int -> public_key * private_key
val encrypt : public_key -> plaintext -> ciphertext
val decrypt : public_key -> private_key -> ciphertext -> plaintext

(* === Basic Homomorphic Operations === *)
val add : public_key -> ciphertext -> ciphertext -> ciphertext
val sub : public_key -> ciphertext -> ciphertext -> ciphertext
val mult : public_key -> ciphertext -> plaintext -> ciphertext
val neg : public_key -> ciphertext -> ciphertext

(* === Vector Operations === *)
(** Vector encryption and homomorphic operations.
    
    Performance note: For vectors with >10,000 elements, operations may become
    computationally expensive. Time complexity is generally O(n) where n is the
    vector size. Memory usage scales linearly with vector size. Consider using
    batch or parallel operations for large vectors. *)
val encrypt_vector : public_key -> float array -> ciphertext array
val decrypt_vector : public_key -> private_key -> ciphertext array -> float array
val add_vectors : public_key -> ciphertext array -> ciphertext array -> ciphertext array
val inner_product : public_key -> ciphertext array -> float array -> ciphertext

(* === Matrix Operations === *)
(** Matrix homomorphic operations.
    
    Performance note: Matrix operations have the following complexities:
    - encrypt_matrix/decrypt_matrix: O(rows × cols)
    - matrix_add: O(rows × cols)
    - matrix_mult: O(rows × cols × inner_dimension)
    - matrix_transpose: O(rows × cols)
    
    For matrices larger than 1000×1000, consider chunking the computation or
    using a distributed computing approach. *)
val encrypt_matrix : public_key -> float array array -> matrix
val decrypt_matrix : public_key -> private_key -> matrix -> float array array
val matrix_add : public_key -> matrix -> matrix -> matrix
val matrix_mult : public_key -> matrix -> float array array -> matrix
val matrix_transpose : matrix -> matrix

(* === Batch Operations === *)
(** Batch operations for efficient processing of multiple values at once.
    
    Example usage:
    ```
    (* Encrypt multiple values in a single batch *)
    let values = [|1.0; 2.0; 3.0; 4.0; 5.0|]
    let encrypted = batch_encrypt public_key values
    
    (* Perform homomorphic addition on batches *)
    let batch1 = batch_encrypt public_key [|1.0; 2.0; 3.0|]
    let batch2 = batch_encrypt public_key [|4.0; 5.0; 6.0|]
    let sum_batch = batch_add public_key batch1 batch2
    let result = batch_decrypt public_key private_key sum_batch
    (* result = [|5.0; 7.0; 9.0|] *)
    ```
    
    Performance improvement: Batch operations typically provide 2-4x speedup
    compared to sequential processing of individual elements. *)
val batch_encrypt : public_key -> float array -> ciphertext array
val batch_decrypt : public_key -> private_key -> ciphertext array -> float array
val batch_add : public_key -> ciphertext array -> ciphertext array -> ciphertext array
val batch_mult : public_key -> ciphertext array -> float array -> ciphertext array

(* === Parallel Operations === *)
val parallel_encrypt : public_key -> float array -> ciphertext array
val parallel_decrypt : public_key -> private_key -> ciphertext array -> float array

(* === Key Management === *)
(** Creates a key rotation module with specified parameters.
    
    Example usage:
    ```
    (* Create a key rotation module that rotates keys every 30 days with 2048-bit keys *)
    let key_manager = create_key_rotation (30 * 24 * 60 * 60) 2048
    
    (* Get the current keys *)
    let (pub_key, priv_key) = (module KeyRotation).current_key ()
    
    (* Force a key rotation *)
    let (new_pub_key, new_priv_key) = (module KeyRotation).rotate_keys ()
    
    (* Check when the last rotation occurred (Unix timestamp) *)
    let last_time = (module KeyRotation).last_rotation ()
    ```
    
    Recommended rotation intervals:
    - Standard security: 30-90 days
    - High security: 7-30 days
    - Critical systems: Consider more frequent rotations (1-7 days)
    
    @param rotation_period The key rotation period in seconds
    @param key_bits The bit length of the generated keys
    @return A key rotation module implementing the KeyRotation interface *)
val create_key_rotation : int -> int -> (module KeyRotation)
val export_public_key : public_key -> string
val import_public_key : string -> public_key
val export_private_key : private_key -> string
val import_private_key : string -> private_key

(* === Utility Functions === *)
val generate_prime : int -> Z.t
val is_probable_prime : Z.t -> int -> bool
val mod_inverse : Z.t -> Z.t -> Z.t option