---
description: Implement openapi standard
---

# Add OpenAPI Support to an Existing Slim PHP REST API

## Objective

Add OpenAPI documentation support to the existing PHP REST API without changing its current architecture or behavior.

The implementation should:

1. Generate an OpenAPI specification from PHP 8 attributes.
2. Use `zircote/swagger-php`.
3. Document all existing API endpoints.
4. Define reusable request and response schemas where appropriate.
5. Generate an `openapi.yaml` file automatically.
6. Expose the generated OpenAPI specification through the application.
7. Add an interactive API documentation page using Swagger UI or Scalar.
8. Keep the existing Slim routes and controllers intact.
9. Avoid unnecessary refactoring.
10. Make OpenAPI generation part of the normal development workflow.

Optional, after the documentation implementation is complete:

11. Add OpenAPI request validation using `league/openapi-psr7-validator`.

The existing API behavior must not change.

# Default Decisions (already confirmed — do not re-ask unless the user objects)

These were decided with the user during the first implementation
(ax-suite-contest `api/`, 2026-08). Use them as defaults and only ask if the
project has a conflicting constraint:

| Decision | Default |
|----------|---------|
| Generator | `zircote/swagger-php` `^6.5` as **require-dev** (attributes are only reflected at generation time; runtime never needs the classes) |
| Validator | `league/openapi-psr7-validator` latest stable (`^0.24` as of 2026-08) as **require** |
| Docs UI | **Swagger UI bundled locally** (offline-capable, no CDN). Only two dist files needed: `swagger-ui.css` + `swagger-ui-bundle.js`, fetched once from `https://unpkg.com/swagger-ui-dist@latest/<file>` and committed to `public/swagger-ui/` |
| OpenAPI version | 3.0.0 (swagger-php 6 default; compatible with the league/cebe validator) |
| Request validation | On, always, no config flag; middleware passes unknown paths through |
| Response validation | **Tests only**, never in production |
| Spec file | `public/openapi.yaml`, generated AND committed (deploy + validator + freshness test read it) |
| Runners | Both a `tools/generate_openapi.bat` (project bat convention) and a composer script `"openapi": "openapi src --output public/openapi.yaml"` |

# Lessons Learned (first implementation — apply these directly)

**swagger-php 6 API differences:**

* In-process: `(new \OpenApi\Generator($logger))->generate([$srcDir])` — there is no static `Generator::scan()` in v6.
* CLI: `vendor/bin/openapi src --output public/openapi.yaml`. The CLI `--version` flag is the OpenAPI *spec* version (requires a value), not the tool version — don't use it to smoke-test the install.
* Set an explicit `description:` on every operation attribute. If omitted, swagger-php lifts the class PHPDoc block into the spec as the operation description (noisy internal comments leak into public docs).
* Same leak for schemas: when a class-level `#[OA\Schema]` sits on a class that has a PHPDoc block, swagger-php attaches that docblock as the `description` of the schema's FIRST property (e.g. `Input.block_type.description` = "Super-admin CRUD for..."). Always give the first `OA\Property` of a class-level schema an explicit `description:` — or put schemas on dedicated docblock-free classes, which is immune by construction. Grep the generated yaml for docblock phrases to catch it.
* Pass a collecting PSR-3 logger to `Generator` in tests and fail on any warning/error — this is how "generation must complete without warnings" gets enforced automatically.

**Subdirectory installs (e.g. WAMP `http://localhost/<project>/api/`):**

* Use `#[OA\Server(url: './')]` (relative) in the spec.
* Swagger UI resolves relative server URLs against the **host root**, not the spec location — "Try it out" then misses the install prefix (404). Fix in the docs HTML with a `requestInterceptor` that pins outgoing URLs to the prefix derived from `window.location`:

```js
var apiBase = new URL(
    window.location.pathname.replace(/\/docs\/?$/, ''),
    window.location.origin
).href;
window.ui = SwaggerUIBundle({
    url: apiBase + '/openapi.yaml',
    dom_id: '#swagger-ui',
    requestInterceptor: function (req) {
        var origin = window.location.origin;
        if (req.url.indexOf(origin + '/') === 0 && req.url.indexOf(apiBase) !== 0) {
            req.url = apiBase + req.url.substring(origin.length);
        }
        return req;
    }
});
```

* The validation middleware must strip the Slim base path from the request URI before matching against spec paths (spec has `/v1/x`, request has `/<project>/api/v1/x`). Pass `$app->getBasePath()` into the middleware constructor.

**Dark mode (Swagger UI ships light-only):**

Add this to the docs HTML — invert the page for dark-scheme users, re-invert media. Counter-intuitive detail: `html` must be `background: #fff`, because the filter inverts the element's OWN background (a dark value would render light).

```css
@media (prefers-color-scheme: dark) {
    html {
        filter: invert(88%) hue-rotate(180deg);
        background: #fff;
    }
    img,
    .swagger-ui .microlight {
        filter: invert(100%) hue-rotate(180deg);
    }
}
```

**Apache gotcha:**

* If the project has a real `docs/` directory (markdown docs), mod_dir 301s `/docs` → `/docs/` **before** the `.htaccess` rewrite runs, breaking a Slim `/docs` route. Fix in the root `.htaccess`: `DirectorySlash Off` plus `Options -Indexes` (without the slash redirect, autoindex could otherwise list directories).

**Serving spec + UI:**

* Serve `/openapi.yaml`, `/docs`, and the UI assets through small Slim routes (a shared `$serveFile` closure + a filename→content-type allowlist for `/docs/{file}`). This stays correct under any docroot/base-path; direct file URLs do not.

**league/openapi-psr7-validator specifics:**

* `NoPath extends ValidationFailed` — catch `NoPath` FIRST and pass the request through (Slim keeps handling 404s and non-API routes like `/docs`), then catch `ValidationFailed` → 400 in the API's existing error shape.
* The useful violation detail is in `$e->getPrevious()->getMessage()`; the outer exception only names the operation.
* Skip validation silently when the spec file doesn't exist yet (fresh checkout before first generation).
* Register the SAME middleware in the PHPUnit base test case — every existing test then exercises request validation for free (behavior-change canary).
* Response validation in tests: `(new ValidatorBuilder())->fromYamlFile($spec)->getResponseValidator()->validate(new OperationAddress($path, strtolower($method)), $response)`.

**Tests that proved their worth (copy these):**

1. Generation succeeds with zero warnings (collecting logger, see above).
2. Route coverage: Slim `$app->getRouteCollector()->getRoutes()` signatures (`"METHOD /pattern"`) vs spec path signatures; keep an explicit `UNDOCUMENTED_ROUTES` ignore list for `/docs`, `/docs/{file}`, `/openapi.yaml`.
3. Freshness guard: in-memory `->toYaml()` equals the committed `public/openapi.yaml` (normalize `\r\n` before comparing) — catches "edited attributes, forgot to regenerate".
4. Response-vs-spec validation on the real endpoints with real fixtures.

**Structure that worked (no DTOs needed):**

* Global metadata + operations for closure-registered routes (health check) live together in one `src/OpenApi/OpenApiDefinition.php` class.
* When responses are shaped by Presenter classes returning arrays (no DTOs), put the `#[OA\Schema]` on the Presenter — documentation next to the code producing the shape; do NOT invent DTO classes just for OpenAPI.
* After implementation, add a binding rule to the project's CODING_RULES.md (or CLAUDE.md): every endpoint create/edit updates attributes + regenerates the spec; the coverage/freshness tests enforce it.

# Phase 1: Analyze the Existing API

Before modifying anything, inspect the project.

Determine:

* PHP version
* Slim version
* Existing directory structure
* Route definitions
* Controller or Action classes
* Request DTOs
* Response DTOs
* Entities or models used in API responses
* Existing validation
* Existing authentication
* Existing error handling
* Existing Composer scripts
* Existing test setup

Locate all Slim routes.

Typical examples may look like:

```php
$app->get('/users/{id}', GetUserAction::class);
$app->post('/users', CreateUserAction::class);
$app->delete('/users/{id}', DeleteUserAction::class);
```

Create an internal inventory of all API endpoints containing:

```text
HTTP method
path
controller
request parameters
request body
response body
possible response status codes
authentication requirements
```

Do not modify the API yet.

# Phase 2: Install OpenAPI Support

Install:

```bash
composer require zircote/swagger-php
```

Verify that the command exists:

```bash
./vendor/bin/openapi --version
```

Do not introduce another OpenAPI generator unless there is a strong technical reason.

Use PHP 8 attributes rather than docblock annotations.

Use:

```php
use OpenApi\Attributes as OA;
```

# Phase 3: Add Global OpenAPI Metadata

Create a dedicated class such as:

```text
src/OpenApi/OpenApi.php
```

Example:

```php
<?php

namespace App\OpenApi;

use OpenApi\Attributes as OA;

#[OA\Info(
    title: 'API',
    version: '1.0.0',
    description: 'REST API documentation'
)]
#[OA\Server(
    url: '/'
)]
final class OpenApi
{
}
```

Adapt the namespace to the existing project.

Do not hardcode a production hostname unless the project already has a canonical API URL configuration.

Prefer relative server URLs when practical.

# Phase 4: Document Existing Routes

Add OpenAPI attributes to the controller or action responsible for each route.

Example existing route:

```php
$app->get('/users/{id}', GetUserAction::class);
```

The corresponding action could contain:

```php
use OpenApi\Attributes as OA;

#[OA\Get(
    path: '/users/{id}',
    operationId: 'getUser',
    summary: 'Get a user',
    tags: ['Users'],
    parameters: [
        new OA\Parameter(
            name: 'id',
            in: 'path',
            required: true,
            schema: new OA\Schema(
                type: 'integer'
            )
        )
    ],
    responses: [
        new OA\Response(
            response: 200,
            description: 'User returned successfully'
        ),
        new OA\Response(
            response: 404,
            description: 'User not found'
        )
    ]
)]
final class GetUserAction
{
    // existing implementation
}
```

Do not duplicate route logic.

The Slim route remains the source of runtime routing.

The OpenAPI attribute documents that route.

# Phase 5: Use Stable Operation IDs

Every operation must have a unique `operationId`.

Use predictable names.

Examples:

```text
listUsers
getUser
createUser
updateUser
deleteUser

listTemplates
getTemplate
createTemplate
updateTemplate
deleteTemplate
```

Avoid autogenerated identifiers.

The identifiers may later be used by:

* generated SDKs
* automated tests
* AI tools
* MCP integrations

Therefore they should remain stable over time.

# Phase 6: Add Tags

Group endpoints logically.

Examples:

```php
tags: ['Users']
```

```php
tags: ['Templates']
```

```php
tags: ['Authentication']
```

```php
tags: ['Sweepstakes']
```

Do not use one unique tag per endpoint.

# Phase 7: Document Path Parameters

Every Slim path parameter must appear in OpenAPI.

Example Slim route:

```text
/templates/{templateId}
```

Document:

```php
new OA\Parameter(
    name: 'templateId',
    in: 'path',
    required: true,
    schema: new OA\Schema(
        type: 'integer'
    )
)
```

The OpenAPI parameter name must exactly match the Slim route placeholder.

# Phase 8: Document Query Parameters

Example:

```text
GET /users?page=2&limit=50
```

Document:

```php
parameters: [
    new OA\Parameter(
        name: 'page',
        in: 'query',
        required: false,
        schema: new OA\Schema(
            type: 'integer',
            minimum: 1
        )
    ),
    new OA\Parameter(
        name: 'limit',
        in: 'query',
        required: false,
        schema: new OA\Schema(
            type: 'integer',
            minimum: 1,
            maximum: 100
        )
    )
]
```

Inspect the existing implementation and document the actual constraints.

Do not invent validation rules that the application does not enforce.

# Phase 9: Document Request Bodies

For endpoints accepting JSON, describe the complete request body.

Example:

```php
requestBody: new OA\RequestBody(
    required: true,
    content: new OA\JsonContent(
        required: ['name', 'email'],
        properties: [
            new OA\Property(
                property: 'name',
                type: 'string'
            ),
            new OA\Property(
                property: 'email',
                type: 'string',
                format: 'email'
            )
        ]
    )
)
```

Prefer reusable schemas instead of repeating large request definitions.

# Phase 10: Create Reusable Schemas

Inspect existing DTOs first.

If the project already has DTO classes, add OpenAPI schema metadata there when reasonable.

Example:

```php
<?php

namespace App\Dto;

use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: 'User',
    required: ['id', 'name']
)]
final class UserDto
{
    #[OA\Property(
        type: 'integer'
    )]
    public int $id;

    #[OA\Property(
        type: 'string'
    )]
    public string $name;

    #[OA\Property(
        type: 'string',
        format: 'email',
        nullable: true
    )]
    public ?string $email;
}
```

Then reference it:

```php
new OA\Response(
    response: 200,
    description: 'User',
    content: new OA\JsonContent(
        ref: '#/components/schemas/User'
    )
)
```

Prefer this over defining the same object repeatedly.

# Phase 11: Separate Input and Output Schemas

Do not automatically assume that the request and response objects have identical structures.

For example:

```text
CreateUserRequest
UserResponse
UpdateUserRequest
```

A create request might contain:

```json
{
    "name": "John",
    "email": "john@example.com"
}
```

while the response might contain:

```json
{
    "id": 123,
    "name": "John",
    "email": "john@example.com",
    "createdAt": "2026-08-15T10:00:00Z"
}
```

Model these separately if the actual API behaves this way.

# Phase 12: Accurately Document Response Codes

Inspect the actual implementation.

For every endpoint document realistic response codes.

Common examples:

```text
200
201
204
400
401
403
404
409
422
500
```

Do not blindly add all of these to every endpoint.

Only document responses that can actually occur.

# Phase 13: Define Common Error Responses

If the API uses a standardized error format such as:

```json
{
    "error": "invalid_request",
    "message": "The email address is invalid"
}
```

create a reusable schema.

Example:

```php
#[OA\Schema(
    schema: 'ApiError',
    required: ['error', 'message']
)]
final class ApiErrorSchema
{
    #[OA\Property(
        type: 'string'
    )]
    public string $error;

    #[OA\Property(
        type: 'string'
    )]
    public string $message;
}
```

Use this schema consistently.

# Phase 14: Document Authentication

Inspect how the API authenticates requests.

If it uses Bearer tokens, define:

```php
#[OA\SecurityScheme(
    securityScheme: 'bearerAuth',
    type: 'http',
    scheme: 'bearer'
)]
```

Authenticated operations can then contain:

```php
security: [
    ['bearerAuth' => []]
]
```

Do not document authentication that the API does not actually use.

If some routes are public, do not apply authentication globally unless that matches the actual application behavior.

# Phase 15: Generate the OpenAPI File

Add generation to Composer.

Example:

```json
{
    "scripts": {
        "openapi": "openapi src -o public/openapi.yaml"
    }
}
```

Then:

```bash
composer openapi
```

The result should be:

```text
public/openapi.yaml
```

Generation must complete without warnings.

Treat warnings from `swagger-php` as problems to investigate rather than ignoring them.

# Phase 16: Validate the Generated Document

After generation, verify that the document contains:

```text
openapi
info
paths
components
```

Check that every existing Slim API route appears in `paths`.

Compare the OpenAPI specification against the actual route configuration.

No route should accidentally disappear from documentation.

# Phase 17: Add an OpenAPI Endpoint

Expose the specification through the API.

For example:

```text
GET /openapi.yaml
```

or:

```text
GET /openapi.json
```

If `public/openapi.yaml` is directly accessible through the existing web server configuration, an extra Slim route may not be necessary.

Use the simplest solution compatible with the existing deployment setup.

# Phase 18: Add Interactive Documentation

Add an API documentation page.

Preferred options:

```text
/docs
```

using either:

```text
Swagger UI
```

or:

```text
Scalar
```

The documentation page should load:

```text
/openapi.yaml
```

Do not embed a separately maintained copy of the OpenAPI specification.

There must be exactly one generated specification used by all consumers.

# Phase 19: Ensure Existing Tests Still Pass

Run the complete existing test suite.

Examples:

```bash
composer test
```

or the project's existing test command.

Do not modify production behavior simply to make OpenAPI generation easier.

OpenAPI should document the existing API.

It should not redefine how the API works.

# Phase 20: Add an OpenAPI Generation Test

Add automated verification that the OpenAPI specification can be generated.

At minimum, CI should execute:

```bash
composer openapi
```

and fail if generation fails.

Preferably also validate the generated specification.

The goal is to prevent broken OpenAPI attributes from being committed.

# Phase 21: Check Route Coverage

Create a small automated test if practical that compares Slim routes against OpenAPI paths.

For each relevant Slim route, verify that the corresponding:

```text
path
HTTP method
```

exists in the generated OpenAPI specification.

Ignore routes that intentionally should not be public API documentation, such as:

```text
/docs
/openapi.yaml
health checks
internal debug routes
```

if appropriate.

This test helps prevent developers from adding a new API route while forgetting its OpenAPI documentation.

# Phase 22: Keep Documentation Close to the Code

Prefer:

```text
Route
    ↓
Action or Controller
    ↓
OpenAPI operation attribute
```

and:

```text
DTO
    ↓
OpenAPI schema attributes
```

Avoid creating one enormous centralized PHP file containing documentation for every endpoint.

Keeping documentation near the implementation makes maintenance easier.

# Phase 23: Avoid Duplicating Domain Models

Before introducing an OpenAPI schema class, inspect whether an appropriate DTO already exists.

Prefer enriching an existing API DTO with OpenAPI metadata.

Do not add parallel classes such as:

```text
User.php
UserDto.php
UserOpenApi.php
UserSchema.php
```

unless there is a real architectural need.

Avoid unnecessary abstraction.

# Phase 24: Nullable and Optional Properties

Pay careful attention to the difference between:

```text
required
optional
nullable
```

These are not the same.

For example:

```json
{
    "middleName": null
}
```

means the property exists but accepts `null`.

An optional property may be completely absent.

Document the actual API behavior.

# Phase 25: Arrays

For lists, specify the item type.

Example:

```php
new OA\JsonContent(
    type: 'array',
    items: new OA\Items(
        ref: '#/components/schemas/User'
    )
)
```

Do not leave arrays untyped.

# Phase 26: Dates

Document date values using appropriate formats.

For timestamps:

```php
new OA\Property(
    property: 'createdAt',
    type: 'string',
    format: 'date-time'
)
```

For dates without time:

```php
format: 'date'
```

# Phase 27: Enums

If the application uses an enum, expose the accepted values.

Example:

```php
new OA\Property(
    property: 'status',
    type: 'string',
    enum: [
        'draft',
        'active',
        'finished'
    ]
)
```

If PHP enums already exist, investigate whether the OpenAPI schema can reuse their values rather than maintaining a duplicate list.

Avoid duplicated sources of truth where possible.

# Phase 28: Pagination

If the API has paginated resources, document the pagination format consistently.

Example response:

```json
{
    "items": [],
    "page": 1,
    "limit": 50,
    "total": 123
}
```

Prefer reusable schemas such as:

```text
PaginationMetadata
```

when multiple endpoints use the same structure.

# Phase 29: Examples

Add useful examples where they significantly improve the documentation.

For example:

```php
new OA\Property(
    property: 'email',
    type: 'string',
    format: 'email',
    example: 'john@example.com'
)
```

Avoid filling the specification with meaningless examples.

Examples should help a developer understand how to call the API.

# Phase 30: Descriptions

Keep descriptions concise.

For example:

Good:

```text
Returns the template identified by templateId.
```

Avoid:

```text
This endpoint can be used in order to retrieve a particular template object from the application's underlying database system.
```

Prefer useful technical information over verbose prose.

# Optional Phase 31: Add Runtime OpenAPI Validation

Only implement this after documentation generation works correctly.

Install:

```bash
composer require league/openapi-psr7-validator
```

Because Slim uses PSR 7 requests, the validator can validate incoming requests against the generated OpenAPI specification.

Implement validation as Slim middleware.

Conceptually:

```text
Request
    ↓
OpenAPI validation middleware
    ↓
Authentication
    ↓
Routing
    ↓
Controller
```

The exact middleware order must be determined from the existing application.

Do not change middleware ordering blindly.

Inspect the current stack first.

# Request Validation

The validator should detect issues such as:

```text
missing required fields
wrong property types
invalid enums
invalid path parameters
invalid query parameters
invalid request body
```

Convert validation failures into the API's existing error format.

Do not expose raw validator exceptions to API clients.

# Response Validation

Response validation can also be useful during development and automated testing.

However, avoid adding expensive response validation to production requests without considering performance implications.

A good strategy may be:

```text
development: request and response validation
test: request and response validation
production: request validation only
```

or another configuration appropriate to the project.

Make this decision based on the existing architecture.

# Important Constraint

The OpenAPI specification must describe the actual API.

Do not change application behavior simply because the OpenAPI specification is easier to write differently.

Whenever documentation and implementation disagree, investigate the implementation and determine which behavior is intended.

# Definition of Done

The task is complete when all of the following are true:

* `zircote/swagger-php` is installed.
* PHP 8 attributes are used.
* Global API metadata exists.
* Every public API route is documented.
* Every operation has a stable unique `operationId`.
* Path parameters are documented.
* Query parameters are documented.
* JSON request bodies are documented.
* Response codes are documented.
* Common DTOs use reusable schemas.
* Authentication is represented correctly.
* `composer openapi` generates the specification.
* Generation produces no unexplained warnings.
* `public/openapi.yaml` is generated.
* The OpenAPI file is accessible to API consumers.
* `/docs` provides interactive API documentation.
* Existing API tests still pass.
* OpenAPI generation is checked by tests or CI.
* No unnecessary changes were made to the API architecture.

# Implementation Strategy

Work incrementally.

Use this sequence:

```text
1. Inspect project
2. Inventory routes
3. Install swagger php
4. Add global OpenAPI metadata
5. Document one representative endpoint
6. Generate openapi.yaml
7. Verify generation
8. Introduce reusable schemas
9. Document remaining endpoints
10. Add authentication definition
11. Add docs page
12. Add automated generation check
13. Run complete test suite
14. Review route coverage
15. Optionally add runtime validation
```

After each significant change, run the relevant tests and regenerate the OpenAPI specification.

Do not perform a large rewrite first and test everything only at the end.

# Final Review

Before finishing, compare:

```text
Slim routes
```

against:

```text
OpenAPI paths
```

and report:

```text
number of public Slim operations
number of documented OpenAPI operations
any intentionally undocumented routes
any inconsistencies discovered
```

Also report the files added or modified and any architectural decisions that were necessary.