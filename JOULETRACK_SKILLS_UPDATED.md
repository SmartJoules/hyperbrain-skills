# JouleTRACK Skill Library - Updated for @itsatif's Coding Style

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Skill library following @itsatif's exact coding patterns from RapidPlantBuilderModule
**Version:** 2.0.0
**Updated:** 2026-05-03

---

## ✨ What's New

The JouleTRACK Angular skill has been **updated to match @itsatif's exact coding style** from `RapidPlantBuilderModule` and `ConfigService`. Your team will now generate code that matches the existing codebase perfectly!

---

## 🎯 Updated Patterns

### 1. **Component Structure** (From RapidPlantBuilderComponent)
```typescript
@Component({
  selector: 'app-feature',
  templateUrl: './feature.component.html',
  styleUrls: ['./feature.component.css'],
  encapsulation: ViewEncapsulation.None,
})
export class FeatureComponent implements OnInit {
  /**
   * @description The View Model Stream
   * @type {Observable<any>}
   */
  vm$: Observable<any>;

  /**
   * @description The current subscribed site's siteId
   * @type {string}
   */
  siteId: string = '';

  /**
   * @description Creates an instance of FeatureComponent.
   * @param {ConfigService} configService - Service description.
   */
  constructor(private configService: ConfigService) {}

  /**
   * @description Lifecycle hook when component will mount
   */
  ngOnInit(): void {
    // Implementation
  }
}
```

### 2. **Service Structure** (From ConfigService)
```typescript
@Injectable({ providedIn: 'root' })
export class FeatureService {
  /**
   * @description Observable to emit current site from store.
   */
  currentSite$: Observable<Site>;

  /**
   * @description Constructor to initialize dependencies.
   * @param {HttpClient} http - Angular HttpClient.
   * @param {MatSnackBar} snackBar - Material Snackbar.
   */
  constructor(
    private http: HttpClient,
    public snackBar: MatSnackBar,
  ) {
    this.currentSite$ = this.store.pipe(
      select(fromRoot.getSiteState),
      filter((result: Site): boolean => result !== undefined),
    );
  }
}
```

### 3. **Module Structure** (From RapidPlantBuilderModule)
```typescript
@NgModule({
  declarations: [
    // ALL components (including nested)
    FeatureComponent,
    SubComponent1,
    SubComponent2,
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    FormsModule,
    // PrimeNG (primary)
    TableModule,
    ButtonModule,
    // Material (secondary)
    MatButtonModule,
    MatCardModule,
  ],
  providers: [
    FeatureService,
    FeatureStore,
  ],
  exports: [
    SubComponent1,
  ],
})
export class FeatureModule {}
```

---

## 📋 Key @itsatif Patterns

### Documentation Style
- **JSDoc comments** above all classes, methods, properties
- **@description tag** for main purpose
- **@type tag** for property types
- **@param tag** for all parameters
- **@returns tag** for return types

### Type Annotations
```typescript
// ✅ CORRECT: Always declare types
siteId: string = '';
vm$: Observable<any>;
systems$: Observable<Array<Systems>> = new Observable<Array<Systems>>();

// ❌ WRONG: Letting type be inferred
siteId = '';
vm$ = combineLatest([...]);
```

### Observable Patterns
```typescript
// ✅ CORRECT: combineLatest with switchMap/filter/tap/map
this.vm$ = combineLatest([
  this.configService.currentSite$,
  this.route.params,
]).pipe(
  switchMap(([site, param]) =>
    of({ site, param }).pipe(
      filter(({ site, param }) => site.siteId === param.siteId),
      tap(({ site }) => this.siteId = site.siteId),
      map(({ site, param }) => ({ site, param })),
    ),
  ),
);
```

### Store Integration
```typescript
// ✅ CORRECT: Always use filter() to remove undefined
this.currentSite$ = this.store.pipe(
  select(fromRoot.getSiteState),
  filter((result: Site): boolean => result !== undefined),
);
```

### Component Properties
```typescript
// ✅ CORRECT: Public services for component access
constructor(
  private configService: ConfigService,
  public snackBar: MatSnackBar,
  public handleErrorService: HandleErrorService,
) {}

// Component can now call: this.snackBar.open()
```

---

## 🔑 Exact Match Checklist

When your team uses the skill, code will match:

- ✅ **ViewEncapsulation.None** on all components
- ✅ **JSDoc comments** with @description, @type, @param, @returns
- ✅ **Explicit type declarations** on all properties
- ✅ **Observable$ naming** for all observable properties
- ✅ **filter() after store.select()** to remove undefined
- ✅ **combineLatest + switchMap** pattern for site/route changes
- ✅ **public services** (snackBar, handleErrorService) for component access
- ✅ **PrimeNG first** for UI components
- ✅ **Angular Material** for specific needs only
- ✅ **Template and styleUrls** in @Component decorator
- ✅ **All nested components declared** in feature module
- ✅ **FormGroup** with FormControl for forms
- ✅ **OnInit lifecycle hook** implementation

---

## 📊 Comparison: Before vs After

### Before (Generic Angular)
```typescript
@Component({
  selector: 'app-energy',
  templateUrl: './energy.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EnergyComponent {
  data = [];
  constructor(private service: DataService) {}
  ngOnInit() {
    this.service.getData().subscribe(data => this.data = data);
  }
}
```

### After (@itsatif's Style)
```typescript
@Component({
  selector: 'app-energy',
  templateUrl: './energy.component.html',
  styleUrls: ['./energy.component.css'],
  encapsulation: ViewEncapsulation.None,
})
export class EnergyComponent implements OnInit {
  /**
   * @description The energy data observable
   * @type {Observable<EnergyData[]>}
   */
  energyData$: Observable<EnergyData[]> = new Observable<EnergyData[]>();

  /**
   * @description Creates an instance of EnergyComponent.
   * @param {EnergyService} energyService - Service for energy data.
   */
  constructor(private energyService: EnergyService) {}

  /**
   * @description Lifecycle hook when component will mount
   */
  ngOnInit(): void {
    this.energyData$ = this.energyService.fetchData();
  }
}
```

---

## 🚀 How to Use

### For Team Members
```bash
# Just start coding - the skill will automatically apply @itsatif's patterns
"Create a component for displaying chiller efficiency with charts"

# Claude will automatically:
# - Use ViewEncapsulation.None
# - Add JSDoc comments
# - Declare types explicitly
# - Use Observable$ naming
# - Follow the combineLatest pattern
# - Use PrimeNG components
```

### Example Output
When a developer asks for code, they get:
- ✅ Exact @itsatif coding style
- ✅ Proper JSDoc documentation
- ✅ Correct TypeScript types
- ✅ JouleTRACK patterns
- ✅ PrimeNG + Material imports
- ✅ Store integration patterns

---

## 📚 Related Skills

- **jouletrack-onboarding** - Complete team setup
- **jouletrack-angular** - Angular patterns (@itsatif's style)
- **tdd-workflow** - Test-driven development
- **jouletrack-library** - Master skill index

---

## ✅ Benefits

### For Your Team
- **Consistency** - Everyone codes exactly like @itsatif
- **Quality** - Automatic documentation and typing
- **Speed** - No need to memorize patterns
- **Onboarding** - New developers match existing style immediately
- **Code Reviews** - Faster when code matches patterns
- **Maintenance** - Easier with consistent patterns

### For Your Codebase
- **Seamless Integration** - New code matches existing perfectly
- **Documentation** - Every component fully documented
- **Type Safety** - Explicit types everywhere
- **Maintainability** - Consistent patterns across entire codebase

---

## 🎯 What's Different from Generic Angular Skills

### Generic Skills
- Container/Presenter pattern
- OnPush change detection
- destroy$ pattern for cleanup

### @itsatif's Style (Now in Skill)
- ViewEncapsulation.None (not OnPush)
- JSDoc documentation requirements
- Explicit type annotations (never inferred)
- Observable$ naming convention
- combineLatest + switchMap pattern
- filter() after store.select()
- public services for component access
- Template/styleUrls in decorator
- All components declared in module

---

## 📞 Quick Reference

### Key @itsatif Patterns
```typescript
// 1. Component property declaration
siteId: string = '';
vm$: Observable<any>;

// 2. Store observable
this.currentSite$ = this.store.pipe(
  select(fromRoot.getSiteState),
  filter((result: Site): boolean => result !== undefined),
);

// 3. CombineLatest pattern
this.vm$ = combineLatest([
  this.configService.currentSite$,
  this.route.params,
]).pipe(
  switchMap(([site, param]) => of({ site, param })),
);

// 4. Constructor with public services
constructor(
  private configService: ConfigService,
  public snackBar: MatSnackBar,
) {}

// 5. JSDoc pattern
/**
 * @description Method description
 * @param {string} param - Parameter description
 * @returns {void} Return description
 */
```

---

**Ready to use!** Your team will now generate code that perfectly matches @itsatif's coding style from RapidPlantBuilderModule and ConfigService. 🎉

The skill library ensures consistency across your entire team while maintaining the high-quality patterns established in your codebase.
