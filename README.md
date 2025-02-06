# CryptaLearn
CryptaLearn is a privacy-preserving machine learning library in OCaml, implementing federated learning, homomorphic encryption, and differentially private stochastic gradient descent (DP-SGD). This library is designed to enable secure and decentralized machine learning while ensuring user data privacy.

## Features [TODO]
- Federated Learning (FL): Decentralized model training where multiple clients contribute without sharing raw data. 
- Homomorphic Encryption (HE): Secure computation on encrypted data. 
- Differential Privacy (DP): Protection against data leakage by adding noise to computatipns. 

## Installation
### Prerequisites
Ensure you have OCaml and OPAM installed. Then, install the necessary dependencies:
```bash
opam install dune ocamlfind core owl zarith
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
Aggregated Model Updates: [0.966666666667; 0.966666666667; 0.966666666667]
Encrypted: 1272, Decrypted: 1234
Private Value with Noise: 5.174
```

# [TODO] 
Still setting up the project. 