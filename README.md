# CryptaLearn

CryptaLearn is a privacy-preserving machine learning library in OCaml, implementing federated learning, homomorphic encryption, and differentially private stochastic gradient descent (DP-SGD). This library is designed to enable secure and decentralized machine learning while ensuring user data privacy.

## Features
### Federated Learning (FL)
- Decentralized model training across multiple clients
- Neural network implementation with multiple activation functions (ReLU, Sigmoid, Tanh)
- Mini-batch training with proper gradient computation
- Model serialization and aggregation
- Supports weighted model averaging based on client data size

### Homomorphic Encryption (HE)
- Full Paillier cryptosystem implementation
- Secure key generation and management
- Support for encrypted arithmetic operations:
  - Addition of encrypted values
  - Subtraction of encrypted values
  - Multiplication by plaintext
- Vector operations for batch processing
- Key serialization and import/export functionality

### Differential Privacy (DP)
- Multiple noise mechanisms:
  - Laplace mechanism
  - Gaussian mechanism
- Privacy budget tracking and accounting
- Gradient clipping and sanitization
- Advanced composition theorem implementation
- Utility estimation and optimal noise calculation

## Installation
### Prerequisites
Ensure you have OCaml and OPAM installed. Then, install the necessary dependencies:
```bash
opam install dune ocamlfind core zarith
```

### Clone the repository
```bash
git clone https://github.com/chizy7/CryptaLearn.git
cd CryptaLearn
```

### Building and Running
```bash
dune build
```

To run the main executable:
```bash
dune exec bin/main.exe
```

## Example Output
```bash
Testing Federated Learning:         
Final model accuracy: 71.70%

Testing Homomorphic Encryption:
Single value test - Original: 42, Decrypted: 42
Homomorphic addition test - 30 + 12 = 42

Testing Differential Privacy:
Privacy budget spent - Epsilon: 0.4799, Delta: 0.0000
Original values: 5.0 10.0 15.0 20.0 25.0 
Noisy values: -12.2 -4.3 -37.2 28.4 72.9 
Gradient clipping test - Original norm: 8.44, Clipped norm: 3.00
```

## Usage Examples

### Federated Learning
```ocaml
(* Create a model with 2 inputs, 4 hidden nodes, and 1 output *)
let model = create_model [|2; 4; 1|] in

(* Configure training parameters *)
let config = {
  batch_size = 32;
  learning_rate = 0.1;
  num_epochs = 5;
} in

(* Train on client data and get updates *)
let client_update = train_client model client_data config in

(* Aggregate updates from multiple clients *)
let final_model = aggregate_updates [update1; update2; update3]
```

### Homomorphic Encryption
```ocaml
(* Generate encryption keys *)
let pk, sk = generate_keypair 1024 in

(* Encrypt and perform operations *)
let encrypted1 = encrypt pk (Z.of_int 30) in
let encrypted2 = encrypt pk (Z.of_int 12) in
let sum = add pk encrypted1 encrypted2 in
let decrypted = decrypt pk sk sum  (* Result: 42 *)
```

### Differential Privacy
```ocaml
(* Create privacy parameters *)
let params = create_privacy_params 0.1 1e-5 1.0 in

(* Add noise to sensitive data *)
let noisy_data = add_noise Gaussian params original_data in

(* Track privacy budget *)
let accountant = create_accountant Gaussian in
let updated_accountant = update_privacy_budget accountant params in
let (eps_spent, delta_spent) = compute_privacy_spent updated_accountant
```

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT [License](LICENSE).