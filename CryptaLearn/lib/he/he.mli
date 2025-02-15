(** Homomorphic Encryption Functions *)

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

type public_key = (module PublicKey)
type private_key = (module PrivateKey)
type ciphertext = Z.t
type plaintext = Z.t

(* Core encryption operations *)
val generate_keypair : int -> public_key * private_key
val encrypt : public_key -> plaintext -> ciphertext
val decrypt : public_key -> private_key -> ciphertext -> plaintext

(* Homomorphic operations *)
val add : public_key -> ciphertext -> ciphertext -> ciphertext
val sub : public_key -> ciphertext -> ciphertext -> ciphertext
val mult : public_key -> ciphertext -> plaintext -> ciphertext
val neg : public_key -> ciphertext -> ciphertext

(* Vector operations *)
val encrypt_vector : public_key -> float array -> ciphertext array
val decrypt_vector : public_key -> private_key -> ciphertext array -> float array
val add_vectors : public_key -> ciphertext array -> ciphertext array -> ciphertext array
val inner_product : public_key -> ciphertext array -> float array -> ciphertext

(* Key serialization *)
val export_public_key : public_key -> string
val import_public_key : string -> public_key
val export_private_key : private_key -> string
val import_private_key : string -> private_key

(* Utility functions *)
val generate_prime : int -> Z.t
val is_probable_prime : Z.t -> int -> bool
val mod_inverse : Z.t -> Z.t -> Z.t option