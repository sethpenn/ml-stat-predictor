# Contributing to ML Stat Predictor

Thank you for contributing to ML Stat Predictor! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code Style Guidelines](#code-style-guidelines)
- [Git Workflow](#git-workflow)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Development Setup](#development-setup)

## Code Style Guidelines

### Python (Backend, ML, Data Pipeline)

- **Style Guide**: Follow [PEP 8](https://pep8.org/)
- **Formatter**: Use `black` with line length of 100
- **Linter**: Use `ruff` for linting
- **Type Hints**: Required for all function signatures
- **Docstrings**: Use Google-style docstrings for all public functions and classes

```python
def predict_game_outcome(
    home_team: str,
    away_team: str,
    model_version: str = "latest"
) -> Dict[str, float]:
    """Predict the outcome of a game between two teams.

    Args:
        home_team: Name of the home team
        away_team: Name of the away team
        model_version: Version of the model to use

    Returns:
        Dictionary containing win probabilities for each team

    Raises:
        ValueError: If team names are invalid
    """
    pass
```

**Import Order**:
1. Standard library imports
2. Third-party imports
3. Local application imports

Use `isort` to automatically sort imports.

### TypeScript/React (Frontend)

- **Style Guide**: Follow [Airbnb TypeScript Style Guide](https://github.com/airbnb/javascript)
- **Formatter**: Use `prettier` with 2-space indentation
- **Linter**: Use `eslint` with TypeScript rules
- **Component Style**: Prefer functional components with hooks
- **File Naming**: Use PascalCase for components, camelCase for utilities

```typescript
interface GamePredictionProps {
  homeTeam: string;
  awayTeam: string;
  onPredictionUpdate?: (prediction: Prediction) => void;
}

export const GamePrediction: React.FC<GamePredictionProps> = ({
  homeTeam,
  awayTeam,
  onPredictionUpdate,
}) => {
  // Component implementation
};
```

**Component Organization**:
1. Imports
2. Types/Interfaces
3. Component definition
4. Styled components (if any)
5. Export

### SQL

- Use uppercase for SQL keywords: `SELECT`, `FROM`, `WHERE`
- Use snake_case for table and column names
- Include appropriate indexes and constraints

## Git Workflow

### Branch Naming

Follow this naming convention:
- `feature/MLSP-XXX-short-description` - New features
- `bugfix/MLSP-XXX-short-description` - Bug fixes
- `hotfix/MLSP-XXX-short-description` - Production hotfixes
- `refactor/MLSP-XXX-short-description` - Code refactoring
- `docs/MLSP-XXX-short-description` - Documentation updates

Where `MLSP-XXX` is the Jira ticket number.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(scope): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Example**:
```
feat(predictions): add ensemble model for NBA predictions

Implement weighted ensemble combining XGBoost and Neural Network
models for improved prediction accuracy on NBA games.

MLSP-123
```

### Branching Strategy

1. `main` - Production-ready code
2. `develop` - Integration branch for features
3. Feature branches created from `develop`
4. Hotfix branches created from `main`

**Workflow**:
```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/MLSP-123-add-nba-predictions

# Make changes and commit
git add .
git commit -m "feat(predictions): add NBA prediction model"

# Push and create PR
git push origin feature/MLSP-123-add-nba-predictions
```

## Pull Request Process

### Before Submitting

1. **Update from base branch**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout your-feature-branch
   git rebase develop
   ```

2. **Run linters**:
   ```bash
   # Python
   black . --check
   ruff check .
   mypy .

   # TypeScript
   npm run lint
   npm run type-check
   ```

3. **Run tests**:
   ```bash
   # Backend
   pytest

   # Frontend
   npm test

   # E2E
   npm run test:e2e
   ```

4. **Update documentation** if needed

### PR Template

Create a PR with this structure:

```markdown
## Description
Brief description of changes

## Related Issue
MLSP-XXX

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Bullet point list of changes

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
```

### Review Process

1. At least **one approval** required from a team member
2. All CI/CD checks must pass
3. No unresolved comments
4. Branch must be up-to-date with base branch

### Merging

- Use **squash and merge** for feature branches
- Use **merge commit** for release branches
- Delete branch after merging

## Testing Requirements

### Python Testing

**Framework**: `pytest`

**Coverage**: Minimum 80% code coverage

**Test Structure**:
```
tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── e2e/           # End-to-end tests
└── conftest.py    # Shared fixtures
```

**Example**:
```python
import pytest
from app.predictions import predict_game_outcome

def test_predict_game_outcome_valid_teams():
    """Test prediction with valid team names."""
    result = predict_game_outcome("Lakers", "Warriors")

    assert "Lakers" in result
    assert "Warriors" in result
    assert 0 <= result["Lakers"] <= 1
    assert 0 <= result["Warriors"] <= 1
    assert abs(result["Lakers"] + result["Warriors"] - 1.0) < 0.01

@pytest.mark.integration
def test_predict_game_outcome_with_db(db_session):
    """Test prediction with database integration."""
    # Test implementation
    pass
```

**Run tests**:
```bash
# All tests
pytest

# With coverage
pytest --cov=app --cov-report=html

# Specific test file
pytest tests/unit/test_predictions.py

# With markers
pytest -m integration
```

### TypeScript/React Testing

**Framework**: `vitest` + `@testing-library/react`

**Coverage**: Minimum 75% code coverage

**Example**:
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { GamePrediction } from './GamePrediction';

describe('GamePrediction', () => {
  it('renders team names correctly', () => {
    render(<GamePrediction homeTeam="Lakers" awayTeam="Warriors" />);

    expect(screen.getByText('Lakers')).toBeInTheDocument();
    expect(screen.getByText('Warriors')).toBeInTheDocument();
  });

  it('calls onPredictionUpdate when prediction completes', async () => {
    const mockCallback = vi.fn();
    render(
      <GamePrediction
        homeTeam="Lakers"
        awayTeam="Warriors"
        onPredictionUpdate={mockCallback}
      />
    );

    // Trigger prediction
    fireEvent.click(screen.getByRole('button', { name: /predict/i }));

    // Wait for callback
    await waitFor(() => expect(mockCallback).toHaveBeenCalled());
  });
});
```

**Run tests**:
```bash
# All tests
npm test

# Watch mode
npm test -- --watch

# Coverage
npm test -- --coverage

# UI mode
npm test -- --ui
```

### ML Model Testing

**Requirements**:
- Unit tests for feature engineering functions
- Integration tests for model pipeline
- Model performance tests with baseline metrics
- Data validation tests

**Example**:
```python
def test_model_performance(trained_model, test_data):
    """Ensure model meets minimum performance requirements."""
    predictions = trained_model.predict(test_data.features)
    accuracy = accuracy_score(test_data.labels, predictions)

    assert accuracy >= 0.65, f"Model accuracy {accuracy} below threshold"
```

### Data Pipeline Testing

**Requirements**:
- Unit tests for scraping functions
- Mock external API calls
- Validate data schemas
- Test error handling and retries

## Development Setup

### Prerequisites

- Python 3.11+
- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 15+

### Setup Steps

1. **Clone repository**:
   ```bash
   git clone https://github.com/your-org/ml-stat-predictor.git
   cd ml-stat-predictor
   ```

2. **Backend setup**:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```

3. **Frontend setup**:
   ```bash
   cd frontend
   npm install
   ```

4. **Environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Database setup**:
   ```bash
   docker-compose up -d postgres
   alembic upgrade head
   ```

6. **Run development servers**:
   ```bash
   # Backend
   cd backend
   uvicorn app.main:app --reload

   # Frontend
   cd frontend
   npm run dev
   ```

## Questions?

If you have questions, please:
- Check existing documentation in `/docs`
- Open an issue on GitHub
- Ask in the team Slack channel

Thank you for contributing!
