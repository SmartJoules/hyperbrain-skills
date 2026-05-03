# Python Backend Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Python patterns and conventions for DeJoule backend development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL Python development** in DeJoule products:
- Creating FastAPI/Flask services
- Implementing business logic
- Working with databases, IoT data pipelines
- Data processing and analysis
- Testing Python code

---

## 🏗️ Project Architecture

### FastAPI Structure (DeJoule Pattern)
```
src/
├── api/              # API routes
│   ├── v1/          # API version 1
│   │   ├── endpoints/
│   │   └── api.py   # Router setup
├── services/        # Business logic
├── repositories/    # Data access
├── models/          # Database models
├── schemas/         # Pydantic schemas
├── middleware/      # Custom middleware
├── core/           # Configuration
├── utils/          # Utilities
└── main.py         # FastAPI app
```

---

## 🎨 Route Handler Pattern

### FastAPI Endpoint with Validation

```python
from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from datetime import datetime

from ..schemas.feature import FeatureCreate, FeatureResponse, FeatureQuery
from ..services.feature_service import FeatureService
from ..core.dependencies import get_feature_service

router = APIRouter(prefix="/features", tags=["features"])

@router.get("/", response_model=List[FeatureResponse])
async def get_features(
    query: FeatureQuery = Depends(),
    service: FeatureService = Depends(get_feature_service),
) -> List[FeatureResponse]:
    """
    Get features with filtering.

    Args:
        query: Query parameters
        service: Feature service instance

    Returns:
        List of features

    Raises:
        HTTPException: If query fails
    """
    try:
        features = await service.fetch_features(query)
        return features
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )

@router.post("/", response_model=FeatureResponse, status_code=status.HTTP_201_CREATED)
async def create_feature(
    data: FeatureCreate,
    service: FeatureService = Depends(get_feature_service),
) -> FeatureResponse:
    """
    Create a new feature.

    Args:
        data: Feature creation data
        service: Feature service instance

    Returns:
        Created feature

    Raises:
        HTTPException: If creation fails
    """
    try:
        feature = await service.create_feature(data)
        return feature
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )

@router.get("/{feature_id}", response_model=FeatureResponse)
async def get_feature(
    feature_id: str,
    service: FeatureService = Depends(get_feature_service),
) -> FeatureResponse:
    """
    Get a specific feature by ID.

    Args:
        feature_id: Feature ID
        service: Feature service instance

    Returns:
        Feature data

    Raises:
        HTTPException: If feature not found
    """
    try:
        feature = await service.get_feature(feature_id)
        return feature
    except FileNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )
```

---

## 📡 Service Pattern

### Service Layer Pattern

```python
from typing import List
from datetime import datetime

from ..schemas.feature import FeatureCreate, FeatureResponse, FeatureQuery
from ..repositories.feature_repository import FeatureRepository
from ..transformers.feature_transformer import FeatureTransformer
from ..core.logging import logger

class FeatureService:
    """
    Feature business logic service.
    """

    def __init__(
        self,
        repository: FeatureRepository,
        transformer: FeatureTransformer,
    ):
        """
        Initialize feature service.

        Args:
            repository: Feature repository
            transformer: Data transformer
        """
        self.repository = repository
        self.transformer = transformer

    async def fetch_features(self, query: FeatureQuery) -> List[FeatureResponse]:
        """
        Fetch features based on query.

        Args:
            query: Query parameters

        Returns:
            List of feature view models

        Raises:
            Exception: If fetch fails
        """
        try:
            # 1. Fetch from repository
            dtos = await self.repository.find(query)

            # 2. Transform to domain
            domain_models = [
                self.transformer.to_domain(dto) for dto in dtos
            ]

            # 3. Transform to view model
            view_models = [
                self.transformer.to_view_model(domain)
                for domain in domain_models
            ]

            return view_models
        except Exception as e:
            logger.error(f"Error fetching features: {e}")
            raise

    async def create_feature(self, data: FeatureCreate) -> FeatureResponse:
        """
        Create a new feature.

        Args:
            data: Feature creation data

        Returns:
            Created feature view model

        Raises:
            ValueError: If validation fails
            Exception: If creation fails
        """
        try:
            # 1. Validate business logic
            if data.value < 0:
                raise ValueError("Value must be non-negative")

            # 2. Transform to domain
            domain = self.transformer.create_to_domain(data)

            # 3. Save via repository
            saved = await self.repository.save(domain)

            # 4. Transform to view model
            return self.transformer.to_view_model(saved)
        except ValueError:
            raise
        except Exception as e:
            logger.error(f"Error creating feature: {e}")
            raise
```

---

## 🔄 Repository Pattern

### Repository with SQLAlchemy

```python
from typing import List, Optional
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from ..models.feature import FeatureModel
from ..schemas.feature import FeatureQuery, FeatureDomain
from ..core.logging import logger

class FeatureRepository:
    """
    Feature data access repository.
    """

    def __init__(self, session: AsyncSession):
        """
        Initialize feature repository.

        Args:
            session: SQLAlchemy async session
        """
        self.session = session

    async def find(self, query: FeatureQuery) -> List[FeatureModel]:
        """
        Find features based on query.

        Args:
            query: Query parameters

        Returns:
            List of feature DTOs

        Raises:
            Exception: If database error occurs
        """
        try:
            stmt = select(FeatureModel).where(
                and_(
                    FeatureModel.site_id == query.site_id,
                    FeatureModel.timestamp >= query.start_date,
                    FeatureModel.timestamp <= query.end_date,
                )
            ).order_by(FeatureModel.timestamp.asc())

            if query.limit:
                stmt = stmt.limit(query.limit)

            if query.offset:
                stmt = stmt.offset(query.offset)

            result = await self.session.execute(stmt)
            return result.scalars().all()
        except Exception as e:
            logger.error(f"Database error: {e}")
            raise

    async def save(self, domain: FeatureDomain) -> FeatureModel:
        """
        Save a feature.

        Args:
            domain: Feature domain model

        Returns:
            Saved DTO

        Raises:
            Exception: If database error occurs
        """
        try:
            dto = FeatureModel(
                site_id=domain.site_id,
                timestamp=domain.timestamp,
                value=domain.value,
            )

            self.session.add(dto)
            await self.session.commit()
            await self.session.refresh(dto)

            return dto
        except Exception as e:
            await self.session.rollback()
            logger.error(f"Database error: {e}")
            raise

    async def update(
        self,
        feature_id: str,
        updates: dict,
    ) -> FeatureModel:
        """
        Update a feature.

        Args:
            feature_id: Feature ID
            updates: Updates to apply

        Returns:
            Updated DTO

        Raises:
            FileNotFoundError: If feature not found
            Exception: If database error occurs
        """
        try:
            stmt = select(FeatureModel).where(FeatureModel.id == feature_id)
            result = await self.session.execute(stmt)
            dto = result.scalar_one_or_none()

            if not dto:
                raise FileNotFoundError(f"Feature {feature_id} not found")

            for key, value in updates.items():
                setattr(dto, key, value)

            await self.session.commit()
            await self.session.refresh(dto)

            return dto
        except FileNotFoundError:
            raise
        except Exception as e:
            await self.session.rollback()
            logger.error(f"Database error: {e}")
            raise

    async def delete(self, feature_id: str) -> FeatureModel:
        """
        Delete a feature.

        Args:
            feature_id: Feature ID

        Returns:
            Deleted DTO

        Raises:
            FileNotFoundError: If feature not found
            Exception: If database error occurs
        """
        try:
            stmt = select(FeatureModel).where(FeatureModel.id == feature_id)
            result = await self.session.execute(stmt)
            dto = result.scalar_one_or_none()

            if not dto:
                raise FileNotFoundError(f"Feature {feature_id} not found")

            await self.session.delete(dto)
            await self.session.commit()

            return dto
        except FileNotFoundError:
            raise
        except Exception as e:
            await self.session.rollback()
            logger.error(f"Database error: {e}")
            raise
```

---

## 📊 Pydantic Schemas

### Request/Response Schemas

```python
from pydantic import BaseModel, Field, validator
from datetime import datetime
from typing import Optional

class FeatureQuery(BaseModel):
    """Feature query parameters."""

    site_id: str = Field(..., description="Site ID")
    start_date: datetime = Field(..., description="Start date")
    end_date: datetime = Field(..., description="End date")
    limit: Optional[int] = Field(100, ge=1, le=1000, description="Limit results")
    offset: Optional[int] = Field(0, ge=0, description="Offset results")

    @validator('end_date')
    def end_date_after_start_date(cls, v, values):
        """Validate end date is after start date."""
        if 'start_date' in values and v < values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v

    class Config:
        """Pydantic config."""
        json_schema_extra = {
            "example": {
                "site_id": "site-123",
                "start_date": "2026-01-01T00:00:00Z",
                "end_date": "2026-01-31T23:59:59Z",
                "limit": 100,
                "offset": 0,
            }
        }

class FeatureCreate(BaseModel):
    """Feature creation schema."""

    site_id: str = Field(..., description="Site ID")
    timestamp: datetime = Field(..., description="Timestamp")
    value: float = Field(..., ge=0, description="Feature value")
    metadata: Optional[dict] = Field(None, description="Optional metadata")

    @validator('value')
    def value_non_negative(cls, v):
        """Validate value is non-negative."""
        if v < 0:
            raise ValueError('value must be non-negative')
        return v

    class Config:
        """Pydantic config."""
        json_schema_extra = {
            "example": {
                "site_id": "site-123",
                "timestamp": "2026-01-01T00:00:00Z",
                "value": 100.5,
            }
        }

class FeatureResponse(BaseModel):
    """Feature response schema."""

    id: str = Field(..., description="Feature ID")
    site_id: str = Field(..., description="Site ID")
    timestamp: datetime = Field(..., description="Timestamp")
    value: float = Field(..., description="Feature value")
    display_value: str = Field(..., description="Formatted display value")
    created_at: datetime = Field(..., description="Creation timestamp")

    class Config:
        """Pydantic config."""
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": "feature-123",
                "site_id": "site-123",
                "timestamp": "2026-01-01T00:00:00Z",
                "value": 100.5,
                "display_value": "100.50",
                "created_at": "2026-01-01T00:00:00Z",
            }
        }
```

---

## 🔐 Authentication Middleware

### JWT Authentication

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from typing import Optional

from ..core.config import settings

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Get current authenticated user.

    Args:
        credentials: HTTP Bearer credentials

    Returns:
        User data

    Raises:
        HTTPException: If authentication fails
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        token = credentials.credentials
        payload = jwt.decode(
            token,
            settings.secret_key,
            algorithms=[settings.algorithm],
        )

        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception

        return payload
    except JWTError:
        raise credentials_exception

async def get_current_active_user(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Get current active user.

    Args:
        current_user: Current user from token

    Returns:
        User data

    Raises:
        HTTPException: If user is inactive
    """
    if not current_user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user",
        )

    return current_user
```

---

## 🧪 Testing Patterns

### Unit Test Template (pytest)

```python
import pytest
from unittest.mock import Mock, AsyncMock

from ..services.feature_service import FeatureService
from ..schemas.feature import FeatureCreate, FeatureQuery

@pytest.fixture
def mock_repository():
    """Mock repository."""
    return Mock()

@pytest.fixture
def mock_transformer():
    """Mock transformer."""
    return Mock()

@pytest.fixture
def service(mock_repository, mock_transformer):
    """Feature service fixture."""
    return FeatureService(mock_repository, mock_transformer)

@pytest.mark.asyncio
async def test_fetch_features(service, mock_repository, mock_transformer):
    """Test fetching features."""
    # Arrange
    query = FeatureQuery(
        site_id="test",
        start_date=datetime(2026, 1, 1),
        end_date=datetime(2026, 1, 31),
    )

    dtos = [Mock(id="1"), Mock(id="2")]
    domains = [Mock(id="1"), Mock(id="2")]
    view_models = [Mock(id="1"), Mock(id="2")]

    mock_repository.find = AsyncMock(return_value=dtos)
    mock_transformer.to_domain = Mock(side_effect=domains)
    mock_transformer.to_view_model = Mock(side_effect=view_models)

    # Act
    result = await service.fetch_features(query)

    # Assert
    assert result == view_models
    mock_repository.find.assert_called_once_with(query)

@pytest.mark.asyncio
async def test_create_feature(service, mock_repository, mock_transformer):
    """Test creating feature."""
    # Arrange
    data = FeatureCreate(
        site_id="test",
        timestamp=datetime.now(),
        value=100,
    )

    domain = Mock(id="1")
    saved = Mock(id="1")
    view_model = Mock(id="1")

    mock_transformer.create_to_domain = Mock(return_value=domain)
    mock_repository.save = AsyncMock(return_value=saved)
    mock_transformer.to_view_model = Mock(return_value=view_model)

    # Act
    result = await service.create_feature(data)

    # Assert
    assert result == view_model
    mock_repository.save.assert_called_once_with(domain)
```

### Integration Test Template

```python
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from ..main import app
from ..core.database import get_db
from ..models.feature import FeatureModel

# Test database
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

engine = create_async_engine(TEST_DATABASE_URL)
TestingSessionLocal = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

async override_get_db():
    """Override database dependency."""
    async with TestingSessionLocal() as session:
        yield session

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.mark.asyncio
async def test_create_feature():
    """Test creating feature via API."""
    response = client.post(
        "/api/v1/features/",
        json={
            "site_id": "test",
            "timestamp": "2026-01-01T00:00:00Z",
            "value": 100,
        },
    )

    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert "data" in data
```

---

## 🚨 Mandatory Rules

### Code Structure Rules
- ✅ **ALWAYS** use route → service → repository layers
- ✅ **ALWAYS** validate input with Pydantic
- ✅ **ALWAYS** use type hints
- ✅ **ALWAYS** handle errors explicitly
- ✅ **NEVER** skip validation
- ✅ **NEVER** use bare `except` clauses

### Database Rules
- ✅ **ALWAYS** use async/await for database operations
- ✅ **ALWAYS** use repository pattern
- ✅ **ALWAYS** use transactions for multi-step operations
- ✅ **NEVER** write raw SQL (use ORM)
- ✅ **NEVER** expose database models to API

### Error Handling Rules
- ✅ **ALWAYS** use specific exceptions
- ✅ **ALWAYS** log errors with context
- ✅ **ALWAYS** return proper HTTP status codes
- ✅ **NEVER** expose stack traces to client
- ✅ **NEVER** swallow exceptions silently

---

## 📝 Naming Conventions

- `PascalCase` for classes: `FeatureService`
- `snake_case` for functions/variables: `fetch_features`
- `snake_case` for files: `feature_service.py`

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Route → Service → Repository layers used
- [ ] Pydantic validation implemented
- [ ] Type hints added
- [ ] Error handling comprehensive
- [ ] Async/await used correctly
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** FastAPI with Pydantic provides automatic validation - leverage it for robust APIs!
