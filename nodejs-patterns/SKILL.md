---
name: nodejs-patterns
description: Node.js backend patterns and conventions for DeJoule development. Use when writing or reviewing Node.js and Express services, including async patterns, error handling, and API structure.
---

# Node.js Backend Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Node.js patterns and conventions for DeJoule backend development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL Node.js development** in DeJoule products:
- Creating new services, APIs, microservices
- Implementing business logic
- Working with databases, IoT data pipelines
- Error handling and validation
- Testing Node.js code

---

## 🏗️ Project Architecture

### Express API Structure (DeJoule Pattern)
```
src/
├── controllers/       # Request handlers
├── services/         # Business logic
├── repositories/     # Data access layer
├── models/           # Database models
├── middleware/       # Express middleware
├── routes/           # Route definitions
├── validators/       # Input validation schemas
├── utils/            # Utility functions
├── config/           # Configuration
├── types/            # TypeScript types
└── app.ts           # Express app setup
```

---

## 🎨 Controller Pattern

### Controller with Validation

```typescript
import { Request, Response, NextFunction } from 'express';
import { SomeService } from '../services/some.service';
import { createSchema } from '../validators/feature.validator';
import { ValidationError } from '../utils/errors';

/**
 * @description Feature controller
 */
export class FeatureController {
  /**
   * @description Creates an instance of FeatureController.
   * @param {SomeService} someService - Service for business logic.
   */
  constructor(private someService: SomeService) {}

  /**
   * @description Get feature data
   * @param {Request} req - Express request
   * @param {Response} res - Express response
   * @param {NextFunction} next - Express next function
   * @returns {Promise<void>}
   */
  async getData(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      // 1. Validate input
      const { error, value } = createSchema.validate(req.query);

      if (error) {
        throw new ValidationError(error.details[0].message);
      }

      // 2. Call service
      const data = await this.someService.fetchData(value);

      // 3. Send response
      res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * @description Create feature
   * @param {Request} req - Express request
   * @param {Response} res - Express response
   * @param {NextFunction} next - Express next function
   * @returns {Promise<void>}
   */
  async create(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      // 1. Validate input
      const { error, value } = createSchema.validate(req.body);

      if (error) {
        throw new ValidationError(error.details[0].message);
      }

      // 2. Call service
      const result = await this.someService.create(value);

      // 3. Send response
      res.status(201).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}
```

---

## 📡 Service Pattern

### Service Layer Pattern

```typescript
import { FeatureRepository } from '../repositories/feature.repository';
import { DataTransformer } from '../transformers/data.transformer';
import { logger } from '../utils/logger';

/**
 * @description Feature service
 */
export class FeatureService {
  /**
   * @description Creates an instance of FeatureService.
   * @param {FeatureRepository} featureRepository - Repository for data access.
   * @param {DataTransformer} dataTransformer - Transformer for data conversion.
   */
  constructor(
    private featureRepository: FeatureRepository,
    private dataTransformer: DataTransformer
  ) {}

  /**
   * @description Fetch feature data
   * @param {QueryParams} params - Query parameters
   * @returns {Promise<ViewModel[]>} Array of view models
   */
  async fetchData(params: QueryParams): Promise<ViewModel[]> {
    try {
      // 1. Fetch from repository
      const dtos = await this.featureRepository.find(params);

      // 2. Transform to domain
      const domainModels = dtos.map((dto) =>
        this.dataTransformer.toDomain(dto)
      );

      // 3. Transform to view model
      const viewModels = domainModels.map((domain) =>
        this.dataTransformer.toViewModel(domain)
      );

      return viewModels;
    } catch (error) {
      logger.error('Error fetching data:', error);
      throw error;
    }
  }

  /**
   * @description Create feature
   * @param {CreateDto} dto - Data transfer object
   * @returns {Promise<ViewModel>} Created view model
   */
  async create(dto: CreateDto): Promise<ViewModel> {
    try {
      // 1. Transform to domain
      const domain = this.dataTransformer.toDomain(dto);

      // 2. Save via repository
      const saved = await this.featureRepository.save(domain);

      // 3. Transform to view model
      return this.dataTransformer.toViewModel(saved);
    } catch (error) {
      logger.error('Error creating:', error);
      throw error;
    }
  }
}
```

---

## 🔄 Repository Pattern

### Repository with Database

```typescript
import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';

/**
 * @description Feature repository
 */
export class FeatureRepository {
  /**
   * @description Creates an instance of FeatureRepository.
   * @param {PrismaClient} prisma - Prisma client for database access.
   */
  constructor(private prisma: PrismaClient) {}

  /**
   * @description Find records
   * @param {QueryParams} params - Query parameters
   * @returns {Promise<Dto[]>} Array of DTOs
   */
  async find(params: QueryParams): Promise<Dto[]> {
    try {
      return await this.prisma.feature.findMany({
        where: {
          siteId: params.siteId,
          timestamp: {
            gte: params.startDate,
            lte: params.endDate,
          },
        },
        orderBy: {
          timestamp: 'asc',
        },
      });
    } catch (error) {
      logger.error('Database error:', error);
      throw error;
    }
  }

  /**
   * @description Save record
   * @param {DomainModel} domain - Domain model
   * @returns {Promise<Dto>} Saved DTO
   */
  async save(domain: DomainModel): Promise<Dto> {
    try {
      return await this.prisma.feature.create({
        data: {
          siteId: domain.siteId,
          timestamp: domain.timestamp,
          value: domain.value,
        },
      });
    } catch (error) {
      logger.error('Database error:', error);
      throw error;
    }
  }

  /**
   * @description Update record
   * @param {string} id - Record ID
   * @param {Partial<DomainModel>} updates - Partial domain model
   * @returns {Promise<Dto>} Updated DTO
   */
  async update(
    id: string,
    updates: Partial<DomainModel>
  ): Promise<Dto> {
    try {
      return await this.prisma.feature.update({
        where: { id },
        data: updates,
      });
    } catch (error) {
      logger.error('Database error:', error);
      throw error;
    }
  }

  /**
   * @description Delete record
   * @param {string} id - Record ID
   * @returns {Promise<Dto>} Deleted DTO
   */
  async delete(id: string): Promise<Dto> {
    try {
      return await this.prisma.feature.delete({
        where: { id },
      });
    } catch (error) {
      logger.error('Database error:', error);
      throw error;
    }
  }
}
```

---

## 📊 Error Handling

### Custom Error Classes

```typescript
/**
 * @description Base error class
 */
export class AppError extends Error {
  /**
   * @description HTTP status code
   */
  public readonly statusCode: number;

  /**
   * @description Error code for client
   */
  public readonly code: string;

  /**
   * @description Creates an instance of AppError.
   * @param {string} message - Error message
   * @param {number} statusCode - HTTP status code
   * @param {string} code - Error code
   */
  constructor(message: string, statusCode: number, code: string) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * @description Validation error
 */
export class ValidationError extends AppError {
  constructor(message: string) {
    super(message, 400, 'VALIDATION_ERROR');
  }
}

/**
 * @description Not found error
 */
export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} with ID ${id} not found`, 404, 'NOT_FOUND');
  }
}

/**
 * @description Conflict error
 */
export class ConflictError extends AppError {
  constructor(message: string) {
    super(message, 409, 'CONFLICT');
  }
}
```

### Global Error Handler

```typescript
import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';
import { AppError } from '../utils/errors';

/**
 * @description Global error handler
 */
export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  // Log error
  logger.error('Error:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
  });

  // Handle known errors
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.code,
        message: err.message,
      },
    });
    return;
  }

  // Handle unknown errors
  res.status(500).json({
    success: false,
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected error occurred',
    },
  });
}
```

---

## 🔐 Middleware Pattern

### Authentication Middleware

```typescript
import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/auth';
import { UnauthorizedError } from '../utils/errors';

/**
 * @description Extend Express Request
 */
export interface AuthRequest extends Request {
  user?: {
    id: string;
    email: string;
    role: string;
  };
}

/**
 * @description Authentication middleware
 */
export function authMiddleware(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): void {
  try {
    // 1. Get token from header
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      throw new UnauthorizedError('No token provided');
    }

    const token = authHeader.replace('Bearer ', '');

    // 2. Verify token
    const decoded = verifyToken(token);

    // 3. Attach user to request
    req.user = decoded;

    // 4. Continue
    next();
  } catch (error) {
    next(error);
  }
}
```

### Validation Middleware

```typescript
import { Request, Response, NextFunction } from 'express';
import { Schema, ValidationError as JoiValidationError } from 'joi';
import { ValidationError } from '../utils/errors';

/**
 * @description Validation middleware factory
 * @param {Schema} schema - Joi validation schema
 * @returns Express middleware
 */
export function validate(schema: Schema) {
  return (
    req: Request,
    res: Response,
    next: NextFunction
  ): void => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const details = error.details.map((detail) => detail.message).join(', ');
      next(new ValidationError(details));
    } else {
      req.body = value;
      next();
    }
  };
}
```

---

## 🎯 Validation

### Joi Validation Schema

```typescript
import Joi from 'joi';

/**
 * @description Create feature schema
 */
export const createFeatureSchema = Joi.object({
  siteId: Joi.string().required().messages({
    'string.empty': 'Site ID is required',
  }),

  timestamp: Joi.date().iso().required().messages({
    'date.base': 'Timestamp must be a valid date',
  }),

  value: Joi.number().required().messages({
    'number.base': 'Value must be a number',
  }),

  metadata: Joi.object().optional(),
});

/**
 * @description Query params schema
 */
export const querySchema = Joi.object({
  siteId: Joi.string().required(),
  startDate: Joi.date().iso().required(),
  endDate: Joi.date().iso().required(),
  limit: Joi.number().integer().min(1).max(1000).default(100),
  offset: Joi.number().integer().min(0).default(0),
});
```

---

## 🧪 Testing Patterns

### Unit Test Template

```typescript
import { FeatureService } from './feature.service';
import { FeatureRepository } from '../repositories/feature.repository';
import { DataTransformer } from '../transformers/data.transformer';

describe('FeatureService', () => {
  let service: FeatureService;
  let repositoryMock: jest.Mocked<FeatureRepository>;
  let transformerMock: jest.Mocked<DataTransformer>;

  beforeEach(() => {
    repositoryMock = {
      find: jest.fn(),
      save: jest.fn(),
    } as any;

    transformerMock = {
      toDomain: jest.fn(),
      toViewModel: jest.fn(),
    } as any;

    service = new FeatureService(repositoryMock, transformerMock);
  });

  describe('fetchData', () => {
    it('should fetch and transform data', async () => {
      // Arrange
      const params = { siteId: 'test', startDate: new Date(), endDate: new Date() };
      const dtos = [{ id: '1', value: 100 }];
      const domains = [{ id: '1', value: 100 }];
      const viewModels = [{ id: '1', displayValue: '100' }];

      repositoryMock.find.mockResolvedValue(dtos);
      transformerMock.toDomain.mockReturnValue(domains[0]);
      transformerMock.toViewModel.mockReturnValue(viewModels[0]);

      // Act
      const result = await service.fetchData(params);

      // Assert
      expect(result).toEqual(viewModels);
      expect(repositoryMock.find).toHaveBeenCalledWith(params);
    });
  });
});
```

### Integration Test Template

```typescript
import request from 'supertest';
import { app } from '../app';
import { prisma } from '../config/database';

describe('Feature API', () => {
  beforeAll(async () => {
    // Setup database
    await prisma.feature.deleteMany({});
  });

  afterAll(async () => {
    // Cleanup
    await prisma.$disconnect();
  });

  describe('POST /api/features', () => {
    it('should create feature', async () => {
      const response = await request(app)
        .post('/api/features')
        .send({
          siteId: 'test',
          timestamp: new Date().toISOString(),
          value: 100,
        })
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
    });
  });
});
```

---

## 🚨 Mandatory Rules

### Code Structure Rules
- ✅ **ALWAYS** use controller → service → repository layers
- ✅ **ALWAYS** validate input at controller level
- ✅ **ALWAYS** handle errors explicitly
- ✅ **ALWAYS** use TypeScript with strict mode
- ✅ **NEVER** skip validation
- ✅ **NEVER** use `any` type

### Database Rules
- ✅ **ALWAYS** use repository pattern
- ✅ **ALWAYS** use transactions for multi-step operations
- ✅ **ALWAYS** handle database errors
- ✅ **NEVER** write raw SQL (use ORM)
- ✅ **NEVER** expose database models to API

### Error Handling Rules
- ✅ **ALWAYS** use custom error classes
- ✅ **ALWAYS** log errors with context
- ✅ **ALWAYS** return proper HTTP status codes
- ✅ **NEVER** expose stack traces to client
- ✅ **NEVER** swallow errors silently

---

## 📝 Naming Conventions

- `PascalCase` for classes: `FeatureService`
- `camelCase` for methods: `fetchData`
- `kebab-case` for files: `feature.service.ts`

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Memory leaks**
- **Solution:** Close database connections, clear intervals

**Issue: Unhandled promise rejections**
- **Solution:** Always use try-catch, attach `.catch()` handlers

**Issue: Type errors**
- **Solution:** Explicitly type all function parameters and return values

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Controller → Service → Repository layers used
- [ ] Input validation implemented
- [ ] Error handling comprehensive
- [ ] TypeScript types explicit
- [ ] No `any` types
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** Layered architecture keeps code maintainable - Controller handles HTTP, Service handles business logic, Repository handles data.
