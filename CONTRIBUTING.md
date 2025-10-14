# Contributing to WireGuard Static IP VPN

First off, thank you for considering contributing to this project! It's people like you that make this a great resource for the security community.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

**Bug Report Template:**

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Run command '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment:**
 - OS: [e.g. Ubuntu 24.04]
 - WireGuard version: [e.g. v1.0.20210914]
 - Cloud provider: [e.g. OCI, AWS]

**Additional context**
Add any other context about the problem here.

**Logs:**
```
Paste relevant logs here
```
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description** of the suggested enhancement
- **Provide specific examples** to demonstrate the steps
- **Describe the current behavior** and **explain which behavior you expected to see instead**
- **Explain why this enhancement would be useful**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code, add tests if applicable
3. If you've changed documentation, ensure it's clear and comprehensive
4. Ensure your code follows the existing style
5. Write a clear commit message
6. Submit the pull request!

## Development Guidelines

### Documentation

- Use clear, concise language
- Include code examples where appropriate
- Test all commands before documenting them
- Keep security best practices in mind
- Update the README if needed

### Code Style

- Use clear, descriptive variable names
- Comment complex logic
- Follow shell scripting best practices
- Test on Ubuntu 24.04 LTS at minimum

### Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Example:
```
Add support for IPv6 routing

- Implement dual-stack configuration
- Update documentation with IPv6 examples
- Add IPv6 firewall rules

Fixes #123
```

## Testing

Before submitting a PR, please test:

1. Fresh installation on clean Ubuntu 24.04 system
2. All client platforms (at least 2)
3. Firewall rules work correctly
4. Documentation is accurate
5. No existing features are broken

## Areas We Need Help

- [ ] Automated deployment scripts (Ansible, Terraform)
- [ ] Monitoring dashboards (Grafana, Prometheus)
- [ ] Additional platform support (Android, Linux Desktop)
- [ ] Performance optimization guides
- [ ] Translations to other languages
- [ ] Video tutorials
- [ ] Docker containerization
- [ ] IPv6 support
- [ ] Multi-server setups

## Questions?

Feel free to open an issue with the `question` label if you need clarification on anything!

Thank you for contributing! 🎉
