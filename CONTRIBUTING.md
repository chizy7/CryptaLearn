# Contributing to CryptaLearn

Thank you for your interest in contributing to CryptaLearn! This document provides guidelines and instructions for contributing to the project.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Project Structure](#project-structure)

---

## Code of Conduct

### My Commitment
I am committed to maintaining a welcoming and inclusive environment for all contributors, regardless of experience level, background, or identity.

### Expected Behavior
- Be respectful and constructive in discussions
- Focus on what is best for the project
- Accept constructive criticism gracefully
- Show empathy towards other contributors

### Unacceptable Behavior
- Harassment, discrimination, or offensive comments
- Publishing others' private information without permission
- Trolling, insulting/derogatory comments, or personal attacks
- Other conduct which could reasonably be considered inappropriate

---

## Getting Started

### Prerequisites
- **OCaml**: Version 4.14.0 or higher
- **OPAM**: OCaml package manager
- **Dune**: Build system for OCaml
- **Git**: Version control

### Required Libraries
```bash
opam install dune core zarith unix threads
```

---

## Development Setup

### 1. Fork and Clone
```bash
# Fork the repository on GitHub first, then:
git clone https://github.com/YOUR_USERNAME/CryptaLearn.git
cd CryptaLearn
```

### 2. Install Dependencies
```bash
opam install dune core zarith unix threads
```

### 3. Build the Project
```bash
dune build
```

### 4. Run Tests
```bash
# Run unit tests
dune runtest

# Run full test suite
dune exec bin/main.exe -- --seed 42
```

### 5. Verify Everything Works
```bash
# Quick verification
dune clean && dune build && dune runtest
```

---

## How to Contribute

### Types of Contributions

#### Bug Reports
- Use the GitHub issue tracker
- Provide a clear description of the bug
- Include steps to reproduce
- Specify your environment (OS, OCaml version, etc.)
- Include error messages and stack traces

#### Feature Requests
- Open an issue to discuss the feature first
- Explain the use case and benefits
- Consider the impact on existing functionality
- Be open to feedback and alternative approaches

#### Documentation
- Fix typos or unclear explanations
- Add examples and usage guides
- Improve API documentation
- Translate documentation (if applicable)

#### Code Contributions
- Bug fixes
- New features
- Performance improvements
- Refactoring and code cleanup

---

## Coding Standards

### OCaml Style Guide

#### Naming Conventions
```ocaml
(* Module names: PascalCase *)
module FederatedLearning = struct ... end

(* Type names: snake_case *)
type model_config = { ... }
type client_update = { ... }

(* Function names: snake_case *)
let train_client model data config = ...
let aggregate_updates updates = ...

(* Constants: UPPER_SNAKE_CASE *)
let DEFAULT_LEARNING_RATE = 0.1
```

#### Code Formatting
```ocaml
(* Use 2-space indentation *)
let example_function x y =
  let result =
    if x > y then
      x + y
    else
      x - y
  in
  result * 2

(* Keep lines under 100 characters when possible *)
(* Add spaces around operators *)
let sum = a + b * c

(* Use meaningful variable names *)
(* Good *)
let training_loss = compute_loss predictions labels

(* Bad *)
let l = f p l
```

#### Documentation Comments
```ocaml
(** Main documentation comment for the function

    @param model The neural network model
    @param data Training data for the client
    @param config Training configuration parameters
    @return Updated model with gradients
*)
val train_client : model -> client_data -> training_config -> client_update

(* Inline comments for complex logic *)
(* Clip gradients to prevent exploding gradients *)
let clipped = clip_gradients gradients max_norm
```

---

## Testing Guidelines

### Writing Tests

#### Unit Tests
All new features must include unit tests. Add tests to `test/test_CryptaLearn.ml`:

```ocaml
let test_new_feature () =
  Printf.printf "Testing new feature...\n";

  (* Setup *)
  let input = create_test_input () in

  (* Execute *)
  let result = new_feature input in

  (* Verify *)
  assert_true (result > 0) "Result should be positive";
  Printf.printf "  ✓ New feature test passed\n"
```

#### Test Coverage
Aim for comprehensive test coverage:
- **Federated Learning**: Model creation, training, aggregation
- **Homomorphic Encryption**: Key generation, encryption, operations
- **Differential Privacy**: Noise mechanisms, privacy accounting
- **DP-SGD**: Gradient clipping, privacy-utility tradeoff

#### Running Tests
```bash
# Run all unit tests
dune runtest

# Run specific test
dune exec test/test_CryptaLearn.exe

# Run with specific epsilon value
dune exec bin/main.exe -- --dp-epsilon 0.5 --seed 42
```

### Test Requirements
- All tests must pass before submitting a PR
- New features require corresponding tests
- Bug fixes should include regression tests
- Use `--seed 42` for reproducible tests

---

## Pull Request Process

### Before Submitting

1. **Update your branch**
```bash
git checkout main
git pull upstream main
git checkout your-feature-branch
git rebase main
```

2. **Run the full test suite**
```bash
dune clean && dune build && dune runtest
```

3. **Check code formatting**
```bash
# Ensure your code follows OCaml conventions
# Run ocamlformat if available
```

4. **Update documentation**
- Update README.md if needed
- Add/update API documentation

### Submitting the PR

1. **Create a clear title**
   - Good: `Add adaptive privacy budget allocation`
   - Bad: `Fix stuff`

2. **Write a descriptive summary**
```markdown
## Description
Brief description of what this PR does

## Motivation
Why is this change needed?

## Changes Made
- Bullet point list of changes
- Be specific about what was modified

## Testing
How was this tested?
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Related Issues
Fixes #123
Related to #456
```

3. **Request review**
   - Assign appropriate reviewers
   - Be responsive to feedback
   - Make requested changes promptly

### PR Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review of code completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] Tests added/updated and passing
- [ ] No new warnings introduced
- [ ] Commit messages are clear and descriptive

---

## Project Structure

### Module Organization

#### Federated Learning (`lib/fl/`)
- Model creation and management
- Client training (standard and DP-SGD)
- Model aggregation
- Gradient computation

#### Homomorphic Encryption (`lib/he/`)
- Paillier cryptosystem
- Key generation
- Encryption/decryption
- Homomorphic operations

#### Differential Privacy (`lib/dp/`)
- Noise mechanisms (Laplace, Gaussian, Exponential)
- Privacy accounting
- Gradient clipping
- Local differential privacy

---

## Development Workflow

### Feature Development
```bash
# 1. Create feature branch
git checkout -b feature/your-feature-name

# 2. Make changes and commit
git add .
git commit -m "Add feature: description"

# 3. Run tests
dune runtest

# 4. Push and create PR
git push origin feature/your-feature-name
```

### Bug Fix Workflow
```bash
# 1. Create bugfix branch
git checkout -b bugfix/issue-number-description

# 2. Write failing test that reproduces the bug
# 3. Fix the bug
# 4. Verify test now passes
# 5. Commit and push
```

---

## Performance Considerations

### Optimization Guidelines
- Profile before optimizing
- Focus on algorithmic improvements first
- Consider memory usage for large datasets
- Use benchmarks to measure improvements

### Benchmarking
```bash
# Run experiments with timing
./run_privacy_experiments.sh

# Results include timing information for HE operations
```

---

## Security Considerations

### Privacy-Preserving Code
- Never log sensitive data
- Ensure proper noise calibration in DP mechanisms
- Validate privacy budget tracking
- Test privacy guarantees thoroughly

### Cryptographic Operations
- Use established cryptographic libraries
- Follow security best practices
- Document security assumptions
- Review cryptographic code carefully

---

## Documentation Standards

### API Documentation
```ocaml
(** Train a client model with differential privacy guarantees.

    This function implements DP-SGD (Differentially Private Stochastic
    Gradient Descent) following Abadi et al. (2016).

    @param model The initial model to train
    @param data Training data for this client
    @param config DP-SGD configuration including clip_norm and noise_multiplier
    @return Client update with gradients and training statistics

    @raise Invalid_argument if clip_norm <= 0 or noise_multiplier < 0

    Example:
    {[
      let config = {
        batch_size = 32;
        learning_rate = 0.1;
        num_epochs = 5;
        clip_norm = 1.0;
        noise_multiplier = 4.84;
        dp_epsilon = 1.0;
        dp_delta = 1e-5;
      } in
      let update = train_client_dp_sgd model data config
    ]}
*)
val train_client_dp_sgd : model -> client_data -> dp_sgd_config -> client_update
```

### README Updates
When adding features, update:
- Features section
- Usage examples
- Command-line options (if applicable)
- Expected results tables

---

## Getting Help

### Resources
- **Documentation**: See `docs/` directory
- **Issues**: GitHub issue tracker

### Questions?
- Check existing issues and documentation first
- Open a new issue with the `question` label
- Be specific about what you're trying to achieve

---

## Recognition

Contributors will be recognized in:
- Project documentation

---

## License

By contributing to CryptaLearn, you agree that your contributions will be licensed under the MIT License.

---

## Thank You!

Your contributions make CryptaLearn better for everyone. I appreciate your time and effort! 

For questions or concerns, please open an issue.
