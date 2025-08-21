# GitHub Copilot Instructions for private-link-example

*Last Updated: 2025-08-20T02:02:09.014969*

## 🚀 Service Overview
**private-link-example** is a critical component of the Omnistrate platform.

### Repository Information
- **Remote**: https://github.com/omnistrate-community/private-link-example
- **Branch**: k8s-managed-nlb-approach
- **Total Commits**: 22

### Technologies Used
- Make
- GitHub Actions

### Health Status
**Status**: needs_attention
⚠️ Issues found:
- Missing go.mod
- No test files found

## 📊 Recent Activity (Last 30 Days)
### Recent Commits
- `5ed97de` Fix GCP terraform execution identity issue (maziarkaveh, 2025-08-14)
- `59e9cc4` Add K8s-managed NLB approach with proper Git configuration (maziarkaveh, 2025-08-14)

### Files Recently Changed
- K8S_MANAGED_README.md
- README.md
- docs/COMPARISON.md
- docs/README.md
- docs/architecture.md
- docs/configuration.md
- docs/index.md
- docs/installation.md
- docs/security.md
- docs/service-plan-integrated.yaml

## 👥 Top Contributors
- **yuhui**: 11 commits
- **Yuhui**: 9 commits
- **maziarkaveh**: 2 commits

## 📈 File Statistics
- **Total Files**: 32
- **Go Files**: 0
- **Test Files**: 0
- **Total Size**: 134.8 KB

## 🛠️ Development Guidelines

### Code Standards
- Follow Omnistrate platform conventions
- Use goa.design for API development (if applicable)
- Implement comprehensive error handling
- Write unit and integration tests
- Follow Go best practices

### Build Commands
```bash
make build          # Build the service
make test          # Run tests
make lint          # Code quality checks
make run           # Run locally
```

### Integration Points
This service integrates with other Omnistrate components. Check dependencies before making changes.

## 🔧 AI Development Assistance

When working on this service:
1. **Understand Context**: Review recent commits and changes
2. **Follow Patterns**: Use established code patterns from the repository
3. **Test Thoroughly**: Add appropriate tests for new functionality
4. **Document Changes**: Update relevant documentation
5. **Consider Dependencies**: Check impact on other services

### Common Tasks
- **API Changes**: Use goa.design patterns and regenerate code
- **Database**: Follow GORM patterns and create migrations
- **Testing**: Add table-driven tests and mock external dependencies
- **Deployment**: Update Docker and Kubernetes configurations as needed

## 📚 Quick Reference
- **Main Package**: `private-link-example`
- **Entry Point**: Check `cmd/` or `main.go`
- **Configuration**: Look for `config/` directory or environment variables
- **Tests**: `*_test.go` files throughout the codebase

## 🎯 Focus Areas
Based on recent activity, focus development efforts on:
- Configuration management

---
*This file is automatically updated with git data. For the latest information, ensure the MCP integration is running.*
