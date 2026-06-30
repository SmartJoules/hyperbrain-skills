---
name: dejoule-rbac
description: DeJoule/JouleTRACK RBAC knowledge base and implementation guide. Use when adding or reviewing API authorization, route policies, site access checks, role permissions, Angular route/menu/button guards, or policy bootstrap changes in jt-api-v2, legacy JouleTrack-API, or JouleTRACK UI.
---

# DeJoule RBAC

**Scope:** `jt-api-v2`, legacy `JouleTrack-API`, and Angular `JouleTRACK`.
**Goal:** Every protected API must enforce authentication, site access, and action permission on the backend; every UI affordance should mirror the same permission for usability, never as the only security boundary.

---

## Mental Model

DeJoule authorization has three layers:

| Layer | What it proves | Backend source |
|---|---|---|
| Authentication | The request has a valid JWT/session token | `isAuthorized`, auth services, Redis token cache |
| Site access | User can access the selected/requested `siteId` | `UserSiteMaps` / `UserSiteMap`, `hasSiteAccess`, `authService.userHasSiteAccess` |
| Action permission | User's role allows this operation | `Roles.policies`, `config/policy.json`, `hasResourceAccess`, action-specific `can*` policies |

Frontend policy checks hide routes/buttons and improve UX. They do not replace backend policies.

---

## jt-api-v2 Backend Map

| File | Role |
|---|---|
| `config/policies.js` | Sails action-to-policy chain. Default is `['isAuthorized', 'hasSiteAccess', 'hasResourceAccess']`. |
| `config/policy.json` | Canonical nested policy catalog used by role editor and backend action permission mapping. |
| `api/policies/isAuthorized.js` | Verifies Bearer/cookie JWT, validates Redis auth token in production, attaches `req.body._userMeta`, and verifies token site access. |
| `api/policies/hasSiteAccess.js` | Allows token site, or checks user access to `req.params.siteId`. |
| `api/policies/hasResourceAccess.js` | Loads role policy from `Roles`, caches `RBAC-<role>`, maps `req.options.action` to `config/policy.json[*].routePolicyMap.actions`, and enforces `hasAccess`. |
| `api/policies/can*.js` | Action-specific policies for permissions that need explicit checks or custom error codes. |
| `api/models/Roles.js` | DynamoDB model/table `roles`; stores `roleName`, nested `policies`, `policiesBE`, `defpref`, `isDeleted`. |
| `api/models/UserSiteMaps.js` | DynamoDB model/table `usersitemaps`; maps `userId + siteId -> role` plus preferences/status. |
| `api/services/role/role.service.js` | Flattens nested `Roles.policies` for frontend bootstrap. |
| `api/services/role/role.private.js` | Caches role bootstrap as `Role-<role>` and RBAC enforcement policy as `RBAC-<role>`, invalidates on create/update/delete. |
| `api/controllers/siteBootstrap/dejoule-user-policy.js` | Returns flattened policy for the requesting role; role comes from JWT. |
| `api/controllers/user/get-policies.js` | Returns backend default `config/policy.json` for role editor. |
| `api/controllers/user/get-user-policies.js` | Merges default policies with each assigned role's policies. |

### Request Context

Protected actions receive:

```json
{
  "_userMeta": {
    "id": "userId",
    "_role": "roleName",
    "_site": "siteId",
    "name": "User Name"
  }
}
```

Do not trust user-provided `_userMeta`; it is attached by `isAuthorized`.

---

## Policy Shape

### Stored / Edited Shape

`config/policy.json` and `Roles.policies` are nested:

```json
{
  "AC Plant": {
    "displayName": "AC Plant",
    "pageView": false,
    "subHeadings": {
      "command": {
        "displayName": "Command",
        "policies": {
          "write": {
            "displayName": "Write",
            "routePolicyMap": {
              "actions": ["controls/send-command-to-control-asset"]
            },
            "hasAccess": false
          }
        }
      }
    }
  }
}
```

`hasResourceAccess` checks whether `req.options.action` appears in any `routePolicyMap.actions`, then reads that role's corresponding `hasAccess`.

If an action is not listed in `config/policy.json`, `hasResourceAccess` currently allows it by default after auth/site checks. Therefore every sensitive new action must be added to `routePolicyMap.actions` or get an explicit `can*` policy.

### Frontend Bootstrap Shape

`role.service.js` flattens nested policies for the UI:

```js
flattenedPolicies[`${policyKey}_View`] = policyValue.pageView ? "1" : "0";
flattenedPolicies[`${CapitalizedSubHeading}_${CapitalizedPermission}`] =
  innerPolicyValue.hasAccess ? "1" : "0";
```

Examples:
- Module page view: `CONFIGURATOR_SYSTEMS_View`, `AC Plant_View`, `User_View`
- Sub-policy: `Command_Write`, `UserRole_Delete`, `Systems_page_Edit`, `Smart_alert_overview_Create`

Angular usually checks string/number truthiness as `'1'`, `1`, or `+policy[key]`.

---

## Add RBAC For A New jt-api-v2 API

1. Define the route/action in `config/routes.js`.

```js
'POST /m2/v2/site/:siteId/my-feature': { action: 'myFeature/do-thing' },
```

2. Keep the default policy chain unless there is a specific reason to override:

```js
// Usually no explicit entry needed because '*' applies:
'*': ['isAuthorized', 'hasSiteAccess', 'hasResourceAccess'],
```

3. If the route has no `:siteId`, either:
- include `siteId` in params/body and perform an explicit service-level access check, or
- add an explicit policy that checks the correct site source.

`hasSiteAccess` only compares `req.params.siteId` to token/access mapping when a route param exists.

4. Add the action to `config/policy.json`.

```json
"My Feature": {
  "displayName": "My Feature",
  "pageView": false,
  "subHeadings": {
    "my_feature": {
      "displayName": "My Feature",
      "policies": {
        "update": {
          "displayName": "Update",
          "routePolicyMap": {
            "actions": ["myFeature/do-thing"]
          },
          "hasAccess": false
        }
      }
    }
  }
}
```

5. For dangerous or domain-specific operations, add an explicit policy too.

```js
// api/policies/canUpdateMyFeature.js
module.exports = async function (req, res, next) {
  const {
    _userMeta: { _role: roleName },
  } = req.body;

  const roleDetails = await Roles.find({ roleName });
  if (!roleDetails || !roleDetails.length) {
    return res.status(401).send({ err: `This role ${roleName} does not exist.` });
  }

  const policies = JSON.parse(roleDetails[0].policies);
  const allowed = policies?.["My Feature"]?.subHeadings?.my_feature?.policies?.update?.hasAccess;

  if (!allowed) {
    return res.status(403).send({
      message: "You don't have permission to perform this operation.",
      errorCode: "MY_FEATURE_UPDATE_NOT_PERMITTED",
    });
  }
  return next();
};
```

Then map:

```js
'myFeature/do-thing': ['isAuthorized', 'hasSiteAccess', 'hasResourceAccess', 'canUpdateMyFeature'],
```

6. In the controller/service, still use `_userMeta.id`, `_userMeta._role`, and the authorized `siteId` for audit logs and data filtering.

7. Add tests:
- no token -> 401/403
- invalid/expired token -> 401/403
- user lacks site access -> 403
- role lacks action permission -> 403 with stable `errorCode`
- role has action permission -> success
- cross-site request with another `siteId` -> 403

---

## Backend Dos And Don'ts

Do:
- Use Sails policies for route-level checks.
- Add every sensitive action to `config/policy.json`.
- Keep controllers thin; put business logic in services after authorization.
- Use stable `errorCode` values for UI handling.
- Invalidate role caches via role service create/update/delete; do not update `Roles` directly.
- Check `req.params.siteId`; if a site id lives in body/query, validate it explicitly.
- Use `hasResourceAccess` for generic action mapping and `can*` policies for sensitive domain operations.

Do not:
- Trust client-provided `_userMeta`, role, or policy values.
- Depend on UI hiding as the only authorization.
- Add a public bypass in `config/policies.js` unless it is truly unauthenticated/webhook/service-authenticated.
- Leave a new write/delete/control action unmapped in `config/policy.json`.
- Hardcode roles such as `admin` in new code unless matching an existing deliberate exception.
- Log tokens, auth headers, passwords, or full request bodies.

---

## Legacy JouleTrack-API Map

Legacy `JouleTrack-API` uses similar concepts with older files:

| File | Role |
|---|---|
| `config/policies.js` | Maps controller actions to `isAuthorized`, `checkAccess`, and logging policies. |
| `config/policy.json` | Legacy action/request-method policy map. |
| `api/policies/isAuthorized.js` | Verifies JWT and attaches `req._userMeta`. |
| `api/policies/checkAccess.js` | Looks up `Role.policies` and checks action/request method policy, with cache. |
| `api/models/Role.js` | Role model; `roleName`, `policies`, `defpref`, `policiesBE`. |
| `api/models/UserSiteMap.js` | User-site-role mapping. |

When touching legacy routes, follow the local shape in `config/policy.json` and `checkAccess.js`; do not assume v2 nested policy shape unless migrating the endpoint.

---

## JouleTRACK Angular Map

| File | Role |
|---|---|
| `src/app/effects/siteBootstrap.ts` | Fetches site bootstrap and dispatches `PolicyChangedAction({ policy: response.policy })`. |
| `src/app/actions/policy.ts` and `src/app/reducers/policy.ts` | Stores flattened policy map in NgRx. |
| `src/app/sharedServices/user.service.ts` | Exposes `policyUser$`, caches `policiesUser`, and has `checkUserAccess(policy)`. |
| `src/app/guards/role-guard.service.ts` | Route guard checks `route.data.expectedPolicy` against `policyUser$`. |
| `src/app/constants/navigationMenuList.ts` | Menu items include `policy` keys like `User_View`. |
| `src/app/app/app-navigation-menu/app-navigation-menu.component.ts` | Filters nav by policy. |
| `src/app/models/policy.ts` | TypeScript interface for known flattened keys. |
| `src/app/app/user/role/*` | Role editor UI; fetches default nested policies and saves role policies. |

### UI Patterns

Route guard:

```ts
{
  path: 'my-feature',
  canActivate: [AuthGuardService, RoleGuardService],
  data: { expectedPolicy: ['My_feature_Update'] },
}
```

Menu visibility:

```ts
{
  label: 'My Feature',
  route: 'my-feature',
  policy: 'My Feature_View',
}
```

Button/action visibility:

```html
<button
  mat-raised-button
  *ngIf="(policy$ | async)?.My_feature_Update == '1'"
  (click)="save()"
>
  Save
</button>
```

Programmatic guard:

```ts
if (!this.userService.checkUserAccess('My_feature_Update')) {
  return;
}
```

Always pair UI checks with backend policy enforcement.

### Add A New UI Permission

1. Add nested backend permission in `jt-api-v2/config/policy.json`.
2. Ensure role editor displays it through `/m2/user/v2/policies`.
3. Update `src/app/models/policy.ts` with the flattened key if the feature uses typed access.
4. Add the flattened key to route data, menu item, button, or component.
5. Verify bootstrap emits the key for the current role.
6. Verify denied users cannot navigate/click and cannot call API directly.

---

## Permission Naming

Because frontend keys are generated from nested policy names:

| Nested field | Flattened result |
|---|---|
| module `User`, `pageView: true` | `User_View` |
| module `AC Plant`, subheading `command`, policy `write` | `Command_Write` |
| module `CONFIGURATOR_SYSTEMS`, subheading `systems_page`, policy `edit` | `Systems_page_Edit` |
| module `SMART_ALERT`, subheading `smart_alert_overview`, policy `create` | `Smart_alert_overview_Create` |

Use existing casing patterns. Avoid renaming existing module/subheading/policy keys because it changes flattened UI keys and can hide routes/buttons unexpectedly.

---

## Common Implementation Checklist

- [ ] Route exists in `config/routes.js`.
- [ ] Route is not accidentally public in `config/policies.js`.
- [ ] Auth policy attaches `_userMeta`.
- [ ] Site access is checked from route param or explicit service logic.
- [ ] Action is mapped in `config/policy.json` `routePolicyMap.actions`.
- [ ] Dangerous action has explicit `can*` policy if needed.
- [ ] Role cache invalidation goes through role service.
- [ ] Angular uses flattened policy key for nav/route/button.
- [ ] `Policy` interface updated when typed code accesses the key.
- [ ] Tests cover denied and allowed cases.

---

## Review Smells

- New API action is absent from `config/policy.json`.
- Route overrides policies with `true` without webhook/service-auth reason.
- Route has no `:siteId` but reads/writes site data without manual site access check.
- UI checks `user.role === 'admin'` instead of a permission key.
- Frontend hides a control but backend allows the request.
- Controller trusts `role`, `siteId`, or `userId` from request body when `_userMeta` should be used.
- Direct `Roles.update` bypasses cache invalidation.
- Permission key casing does not match flattened bootstrap output.
