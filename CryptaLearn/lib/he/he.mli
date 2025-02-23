(** Homomorphic Encryption Interface *)

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

type matrix = {
  rows: int;
  cols: int;
  data: ciphertext array array;
}

(* === Key Rotation Interface === *)
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
val encrypt_vector : public_key -> float array -> ciphertext array
val decrypt_vector : public_key -> private_key -> ciphertext array -> float array
val add_vectors : public_key -> ciphertext array -> ciphertext array -> ciphertext array
val inner_product : public_key -> ciphertext array -> float array -> ciphertext

(* === Matrix Operations === *)
val encrypt_matrix : public_key -> float array array -> matrix
val decrypt_matrix : public_key -> private_key -> matrix -> float array array
val matrix_add : public_key -> matrix -> matrix -> matrix
val matrix_mult : public_key -> matrix -> float array array -> matrix
val matrix_transpose : matrix -> matrix

(* === Batch Operations === *)
val batch_encrypt : public_key -> float array -> ciphertext array
val batch_decrypt : public_key -> private_key -> ciphertext array -> float array
val batch_add : public_key -> ciphertext array -> ciphertext array -> ciphertext array
val batch_mult : public_key -> ciphertext array -> float array -> ciphertext array

(* === Parallel Operations === *)
val parallel_encrypt : public_key -> float array -> ciphertext array
val parallel_decrypt : public_key -> private_key -> ciphertext array -> float array

(* === Key Management === *)
val create_key_rotation : int -> int -> (module KeyRotation)
val export_public_key : public_key -> string
val import_public_key : string -> public_key
val export_private_key : private_key -> string
val import_private_key : string -> private_key

(* === Utility Functions === *)
val generate_prime : int -> Z.t
val is_probable_prime : Z.t -> int -> bool
val mod_inverse : Z.t -> Z.t -> Z.t option