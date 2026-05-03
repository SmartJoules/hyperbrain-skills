# Go Backend Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Go patterns and conventions for DeJoule backend development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL Go development** in DeJoule products:
- Creating high-performance APIs and microservices
- Implementing IoT data pipelines
- Working with Kafka, MQTT, time-series databases
- Concurrent processing and goroutines
- Testing Go code

---

## 🏗️ Project Architecture

### Standard Go Project Layout
```
cmd/
  └── service/
      └── main.go           # Application entry point
internal/
  ├── handlers/            # HTTP handlers
  ├── services/            # Business logic
  ├── repositories/        # Data access
  ├── models/              # Domain models
  ├── middleware/          # HTTP middleware
  └── validators/          # Input validation
pkg/
  ├── errors/              # Custom errors
  ├── logger/              # Logging utilities
  └── config/              # Configuration
api/
  └── http/                # API definitions (OpenAPI)
go.mod                     # Go modules
go.sum                     # Dependencies checksum
Makefile                   # Build automation
```

---

## 🎨 Handler Pattern

### HTTP Handler with Validation

```go
package handlers

import (
    "encoding/json"
    "errors"
    "net/http"
    "strconv"

    "github.com/gin-gonic/gin"
    "github.com/go-playground/validator/v10"

    "your-project/internal/services"
    "your-project/internal/validators"
    "your-project/pkg/errors"
)

// FeatureHandler handles feature-related requests
type FeatureHandler struct {
    service  services.FeatureService
    validate *validator.Validate
}

// NewFeatureHandler creates a new feature handler
func NewFeatureHandler(service services.FeatureService) *FeatureHandler {
    return &FeatureHandler{
        service:  service,
        validate: validator.New(),
    }
}

// GetFeatures retrieves features with filtering
// @Summary Get features
// @Tags features
// @Accept json
// @Produce json
// @Param site_id query string true "Site ID"
// @Param start_date query string true "Start date (RFC3339)"
// @Param end_date query string true "End date (RFC3339)"
// @Success 200 {object} Response{data=[]models.FeatureViewModel}
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /features [get]
func (h *FeatureHandler) GetFeatures(c *gin.Context) {
    // 1. Parse and validate query parameters
    var query validators.FeatureQuery
    if err := c.ShouldBindQuery(&query); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": gin.H{
                "code":    "VALIDATION_ERROR",
                "message": err.Error(),
            },
        })
        return
    }

    // 2. Call service
    features, err := h.service.FetchFeatures(c.Request.Context(), query)
    if err != nil {
        h.handleError(c, err)
        return
    }

    // 3. Send response
    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data":    features,
    })
}

// CreateFeature creates a new feature
// @Summary Create feature
// @Tags features
// @Accept json
// @Produce json
// @Param feature body validators.FeatureCreate true "Feature data"
// @Success 201 {object} Response{data=models.FeatureViewModel}
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /features [post]
func (h *FeatureHandler) CreateFeature(c *gin.Context) {
    // 1. Parse and validate request body
    var req validators.FeatureCreate
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": gin.H{
                "code":    "VALIDATION_ERROR",
                "message": err.Error(),
            },
        })
        return
    }

    // 2. Call service
    feature, err := h.service.CreateFeature(c.Request.Context(), req)
    if err != nil {
        h.handleError(c, err)
        return
    }

    // 3. Send response
    c.JSON(http.StatusCreated, gin.H{
        "success": true,
        "data":    feature,
    })
}

// GetFeature retrieves a feature by ID
func (h *FeatureHandler) GetFeature(c *gin.Context) {
    // 1. Parse ID from URL
    id := c.Param("id")
    if id == "" {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": gin.H{
                "code":    "VALIDATION_ERROR",
                "message": "ID is required",
            },
        })
        return
    }

    // 2. Call service
    feature, err := h.service.GetFeature(c.Request.Context(), id)
    if err != nil {
        h.handleError(c, err)
        return
    }

    // 3. Send response
    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data":    feature,
    })
}

// handleError handles errors and returns appropriate HTTP responses
func (h *FeatureHandler) handleError(c *gin.Context, err error) {
    var appErr *errors.AppError

    if errors.As(err, &appErr) {
        c.JSON(appErr.StatusCode, gin.H{
            "success": false,
            "error": gin.H{
                "code":    appErr.Code,
                "message": appErr.Message,
            },
        })
        return
    }

    // Unknown error
    c.JSON(http.StatusInternalServerError, gin.H{
        "success": false,
        "error": gin.H{
            "code":    "INTERNAL_SERVER_ERROR",
            "message": "An unexpected error occurred",
        },
    })
}
```

---

## 📡 Service Pattern

### Service Layer Pattern

```go
package services

import (
    "context"
    "fmt"

    "your-project/internal/models"
    "your-project/internal/repositories"
    "your-project/internal/transformers"
    "your-project/internal/validators"
    "your-project/pkg/logger"
)

// FeatureService handles feature business logic
type FeatureService struct {
    repo        repositories.FeatureRepository
    transformer *transformers.FeatureTransformer
}

// NewFeatureService creates a new feature service
func NewFeatureService(
    repo repositories.FeatureRepository,
    transformer *transformers.FeatureTransformer,
) *FeatureService {
    return &FeatureService{
        repo:        repo,
        transformer: transformer,
    }
}

// FetchFeatures retrieves features based on query
func (s *FeatureService) FetchFeatures(
    ctx context.Context,
    query validators.FeatureQuery,
) ([]models.FeatureViewModel, error) {
    // 1. Fetch from repository
    dtos, err := s.repo.Find(ctx, query)
    if err != nil {
        logger.Error("Failed to fetch features", "error", err)
        return nil, fmt.Errorf("failed to fetch features: %w", err)
    }

    // 2. Transform to domain models
    domainModels := make([]models.FeatureDomain, 0, len(dtos))
    for _, dto := range dtos {
        domain := s.transformer.ToDomain(dto)
        domainModels = append(domainModels, domain)
    }

    // 3. Transform to view models
    viewModels := make([]models.FeatureViewModel, 0, len(domainModels))
    for _, domain := range domainModels {
        vm := s.transformer.ToViewModel(domain)
        viewModels = append(viewModels, vm)
    }

    return viewModels, nil
}

// CreateFeature creates a new feature
func (s *FeatureService) CreateFeature(
    ctx context.Context,
    req validators.FeatureCreate,
) (models.FeatureViewModel, error) {
    // 1. Validate business logic
    if req.Value < 0 {
        return models.FeatureViewModel{}, &errors.ValidationError{
            Message: "Value must be non-negative",
        }
    }

    // 2. Transform to domain model
    domain := s.transformer.CreateToDomain(req)

    // 3. Save via repository
    saved, err := s.repo.Save(ctx, domain)
    if err != nil {
        logger.Error("Failed to create feature", "error", err)
        return models.FeatureViewModel{}, fmt.Errorf("failed to create feature: %w", err)
    }

    // 4. Transform to view model
    vm := s.transformer.ToViewModel(saved)
    return vm, nil
}

// GetFeature retrieves a feature by ID
func (s *FeatureService) GetFeature(
    ctx context.Context,
    id string,
) (models.FeatureViewModel, error) {
    // 1. Fetch from repository
    dto, err := s.repo.FindByID(ctx, id)
    if err != nil {
        logger.Error("Failed to get feature", "error", err)
        return models.FeatureViewModel{}, fmt.Errorf("failed to get feature: %w", err)
    }

    // 2. Transform to view model
    domain := s.transformer.ToDomain(dto)
    vm := s.transformer.ToViewModel(domain)
    return vm, nil
}
```

---

## 🔄 Repository Pattern

### Repository with GORM

```go
package repositories

import (
    "context"
    "errors"
    "fmt"

    "gorm.io/gorm"

    "your-project/internal/models"
    "your-project/internal/validators"
    "your-project/pkg/logger"
)

// FeatureRepository handles feature data access
type FeatureRepository struct {
    db *gorm.DB
}

// NewFeatureRepository creates a new feature repository
func NewFeatureRepository(db *gorm.DB) *FeatureRepository {
    return &FeatureRepository{db: db}
}

// Find retrieves features based on query
func (r *FeatureRepository) Find(
    ctx context.Context,
    query validators.FeatureQuery,
) ([]models.FeatureDTO, error) {
    var dtos []models.FeatureDTO

    err := r.db.WithContext(ctx).
        Where("site_id = ?", query.SiteID).
        Where("timestamp >= ?", query.StartDate).
        Where("timestamp <= ?", query.EndDate).
        Order("timestamp ASC").
        Limit(query.Limit).
        Offset(query.Offset).
        Find(&dtos).Error

    if err != nil {
        logger.Error("Database error", "error", err)
        return nil, fmt.Errorf("database error: %w", err)
    }

    return dtos, nil
}

// FindByID retrieves a feature by ID
func (r *FeatureRepository) FindByID(
    ctx context.Context,
    id string,
) (models.FeatureDTO, error) {
    var dto models.FeatureDTO

    err := r.db.WithContext(ctx).
        Where("id = ?", id).
        First(&dto).Error

    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return models.FeatureDTO{}, &errors.NotFoundError{
                Resource: "feature",
                ID:       id,
            }
        }
        logger.Error("Database error", "error", err)
        return models.FeatureDTO{}, fmt.Errorf("database error: %w", err)
    }

    return dto, nil
}

// Save creates or updates a feature
func (r *FeatureRepository) Save(
    ctx context.Context,
    domain models.FeatureDomain,
) (models.FeatureDTO, error) {
    dto := models.FeatureDTO{
        SiteID:    domain.SiteID,
        Timestamp: domain.Timestamp,
        Value:     domain.Value,
    }

    if err := r.db.WithContext(ctx).Create(&dto).Error; err != nil {
        logger.Error("Database error", "error", err)
        return models.FeatureDTO{}, fmt.Errorf("database error: %w", err)
    }

    return dto, nil
}

// Update updates a feature
func (r *FeatureRepository) Update(
    ctx context.Context,
    id string,
    updates map[string]interface{},
) (models.FeatureDTO, error) {
    var dto models.FeatureDTO

    err := r.db.WithContext(ctx).
        Model(&dto).
        Where("id = ?", id).
        Updates(updates).
        Error

    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return models.FeatureDTO{}, &errors.NotFoundError{
                Resource: "feature",
                ID:       id,
            }
        }
        logger.Error("Database error", "error", err)
        return models.FeatureDTO{}, fmt.Errorf("database error: %w", err)
    }

    return dto, nil
}

// Delete deletes a feature
func (r *FeatureRepository) Delete(
    ctx context.Context,
    id string,
) (models.FeatureDTO, error) {
    var dto models.FeatureDTO

    err := r.db.WithContext(ctx).
        Where("id = ?", id).
        Delete(&dto).Error

    if err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return models.FeatureDTO{}, &errors.NotFoundError{
                Resource: "feature",
                ID:       id,
            }
        }
        logger.Error("Database error", "error", err)
        return models.FeatureDTO{}, fmt.Errorf("database error: %w", err)
    }

    return dto, nil
}
```

---

## 📊 Error Handling

### Custom Error Types

```go
package errors

import "net/http"

// AppError represents an application error
type AppError struct {
    Code       string `json:"code"`
    Message    string `json:"message"`
    StatusCode int    `json:"-"`
}

// Error implements the error interface
func (e *AppError) Error() string {
    return e.Message
}

// ValidationError represents a validation error
type ValidationError struct {
    Message string
}

func (e *ValidationError) Error() string {
    return e.Message
}

func (e *ValidationError) Code() string {
    return "VALIDATION_ERROR"
}

func (e *ValidationError) StatusCode() int {
    return http.StatusBadRequest
}

// NotFoundError represents a not found error
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s with ID %s not found", e.Resource, e.ID)
}

func (e *NotFoundError) Code() string {
    return "NOT_FOUND"
}

func (e *NotFoundError) StatusCode() int {
    return http.StatusNotFound
}

// ConflictError represents a conflict error
type ConflictError struct {
    Message string
}

func (e *ConflictError) Error() string {
    return e.Message
}

func (e *ConflictError) Code() string {
    return "CONFLICT"
}

func (e *ConflictError) StatusCode() int {
    return http.StatusConflict
}
```

---

## 🔐 Middleware Pattern

### Authentication Middleware

```go
package middleware

import (
    "net/http"
    "strings"

    "github.com/gin-gonic/gin"

    "your-project/pkg/auth"
)

// AuthMiddleware validates JWT tokens
func AuthMiddleware(authService auth.Service) gin.HandlerFunc {
    return func(c *gin.Context) {
        // 1. Get token from Authorization header
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
                "success": false,
                "error": gin.H{
                    "code":    "UNAUTHORIZED",
                    "message": "No token provided",
                },
            })
            return
        }

        // 2. Extract Bearer token
        tokenString := strings.TrimPrefix(authHeader, "Bearer ")
        if tokenString == authHeader {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
                "success": false,
                "error": gin.H{
                    "code":    "UNAUTHORIZED",
                    "message": "Invalid authorization format",
                },
            })
            return
        }

        // 3. Verify token
        claims, err := authService.VerifyToken(tokenString)
        if err != nil {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
                "success": false,
                "error": gin.H{
                    "code":    "UNAUTHORIZED",
                    "message": "Invalid token",
                },
            })
            return
        }

        // 4. Set user context
        c.Set("user_id", claims.UserID)
        c.Set("email", claims.Email)
        c.Set("role", claims.Role)

        c.Next()
    }
}
```

---

## 🧪 Testing Patterns

### Unit Test Template

```go
package services_test

import (
    "context"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"

    "your-project/internal/models"
    "your-project/internal/services"
    "your-project/internal/validators"
)

// MockRepository is a mock implementation of FeatureRepository
type MockRepository struct {
    mock.Mock
}

func (m *MockRepository) Find(ctx context.Context, query validators.FeatureQuery) ([]models.FeatureDTO, error) {
    args := m.Called(ctx, query)
    return args.Get(0).([]models.FeatureDTO), args.Error(1)
}

func (m *MockRepository) Save(ctx context.Context, domain models.FeatureDomain) (models.FeatureDTO, error) {
    args := m.Called(ctx, domain)
    return args.Get(0).(models.FeatureDTO), args.Error(1)
}

func TestFetchFeatures(t *testing.T) {
    // Setup
    mockRepo := new(MockRepository)
    mockTransformer := new(transformers.MockTransformer)
    service := services.NewFeatureService(mockRepo, mockTransformer)

    query := validators.FeatureQuery{
        SiteID:    "test-site",
        StartDate: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
        EndDate:   time.Date(2026, 1, 31, 23, 59, 59, 0, time.UTC),
        Limit:     100,
        Offset:    0,
    }

    dtos := []models.FeatureDTO{
        {ID: "1", SiteID: "test-site", Value: 100},
        {ID: "2", SiteID: "test-site", Value: 200},
    }

    domains := []models.FeatureDomain{
        {ID: "1", SiteID: "test-site", Value: 100},
        {ID: "2", SiteID: "test-site", Value: 200},
    }

    viewModels := []models.FeatureViewModel{
        {ID: "1", DisplayValue: "100.00"},
        {ID: "2", DisplayValue: "200.00"},
    }

    mockRepo.On("Find", mock.Anything, query).Return(dtos, nil)
    mockTransformer.On("ToDomain", dtos[0]).Return(domains[0])
    mockTransformer.On("ToDomain", dtos[1]).Return(domains[1])
    mockTransformer.On("ToViewModel", domains[0]).Return(viewModels[0])
    mockTransformer.On("ToViewModel", domains[1]).Return(viewModels[1])

    // Execute
    result, err := service.FetchFeatures(context.Background(), query)

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, viewModels, result)
    mockRepo.AssertExpectations(t)
}
```

---

## 🚨 Mandatory Rules

### Code Structure Rules
- ✅ **ALWAYS** use handler → service → repository layers
- ✅ **ALWAYS** validate input at handler level
- ✅ **ALWAYS** handle errors explicitly
- ✅ **ALWAYS** use context for cancellation
- ✅ **NEVER** skip validation
- ✅ **NEVER** ignore errors

### Concurrency Rules
- ✅ **ALWAYS** use goroutines with care
- ✅ **ALWAYS** use channels for communication
- ✅ **ALWAYS** use wait groups to wait for goroutines
- ✅ **NEVER** share mutable state between goroutines without synchronization
- ✅ **NEVER** create goroutines without a way to cancel them

### Database Rules
- ✅ **ALWAYS** use repository pattern
- ✅ **ALWAYS** use transactions for multi-step operations
- ✅ **ALWAYS** handle database errors
- ✅ **NEVER** write raw SQL (use ORM)
- ✅ **NEVER** expose database models to API

---

## 📝 Naming Conventions

- `PascalCase` for exported: `FeatureService`
- `camelCase` for unexported: `internalValue`
- `PascalCase` for interfaces: `Repository`
- `kebab-case` for files: `feature_service.go`

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Handler → Service → Repository layers used
- [ ] Input validation implemented
- [ ] Error handling comprehensive
- [ ] Context used correctly
- [ ] No data races
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** Go's simplicity is its strength - keep code straightforward and idiomatic!
