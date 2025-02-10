(** Homomorphic Encryption Functions *)

module type PublicKey = sig
    val n : Z.t
    val g : Z.t
  end
  
  module type PrivateKey = sig
    val lambda : Z.t
    val mu : Z.t
  end
  
  type public_key = (module PublicKey)
  type private_key = (module PrivateKey)
  type ciphertext = Z.t
  
  val generate_keypair : int -> public_key * private_key
  val encrypt : public_key -> Z.t -> ciphertext
  val decrypt : public_key -> private_key -> ciphertext -> Z.t
  val add : public_key -> ciphertext -> ciphertext -> ciphertext
  val mult : public_key -> ciphertext -> Z.t -> ciphertext