# Contributing

Thank you for your interest in contributing to this project!

## Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Write or update tests as needed
5. **Run all tests locally** (see Testing section below)
6. Commit with descriptive messages (`git commit -am 'Add feature...'`)
7. Push to your fork
8. Create a Pull Request

## Code Standards

- Follow PowerShell best practices
- Use explicit parameter names in function definitions
- Add comment-based help for functions
- Ensure all tests pass before submitting PR
- Use proper error handling with try/catch blocks
- Follow the existing code style and formatting

## Commit Messages

Use conventional commits:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `test:` for test changes
- `ci:` for CI/CD changes
- `refactor:` for code refactoring

Example: `feat: add new BIOS recommendation category`

## Testing

Before submitting a PR, run all three test suites:

### 1. Pester Unit Tests (PowerShell)

```powershell
Remove-Module Pester -Force -ErrorAction SilentlyContinue
Invoke-Pester -Path ./tests -Output Detailed
```

**Requirements:** Already installed on Windows 10/11  
**What it tests:** Script structure, function existence, code patterns

### 2. PSScriptAnalyzer (Code Quality)

```powershell
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings ./scripts/PSScriptAnalyzerSettings.psd1
```

**Requirements:** Already installed on Windows 10/11  
**What it tests:** PowerShell best practices and code quality standards

### 3. Markdown Lint (Documentation)

```powershell
npm install -g markdownlint-cli
markdownlint -c .markdownlint.json .
```

**Requirements:** Node.js and npm (install from [nodejs.org](https://nodejs.org/))
**What it tests:** Documentation formatting and consistency

### Run All Tests

```powershell
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings ./scripts/PSScriptAnalyzerSettings.psd1; `
Remove-Module Pester -Force -ErrorAction SilentlyContinue; `
Invoke-Pester -Path ./tests -Output Detailed; `
markdownlint -c .markdownlint.json .
```

**Test Guidelines:**

- Add tests for new functionality in `/tests`
- Tests use Pester 5.7.1 framework
- All tests must pass before submitting PR
- Test file naming convention: `scriptname.tests.ps1`

## Questions?

Feel free to open an issue to discuss improvements or ask questions.
