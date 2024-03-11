# ParseRoute Library

Designed with efficiency and comprehensiveness in mind, ParseRoute delivers an all-encompassing solution for route parsing, matching, and navigation within Dart applications. Its intuitive API caters to developers by simplifying complex navigation management tasks, making it a highly flexible and scalable choice for integration into various applications and frameworks. Ideal for projects utilizing Navigator 2, or even in server-side Dart applications, ParseRoute is poised to become a foundational component of GetX and GetServer at some point in the future.

## Key Features

- **Dynamic Route Matching:** Simplifies the matching of routes, including those with dynamic segments, and effortlessly extracts relevant parameters for use.
- **Query Parameter Parsing:** Integrates the parsing of URL query parameters directly into the route matching workflow, enhancing data retrieval and usage.
- **Route Registration & Verification:** Enables the easy registration of routes within your application and allows for the immediate verification of their registration status.
- **Nested Route Support:** Facilitates the organization of complex application navigational structures through the use of nested routes.
- **Advanced Programmatic Navigation:** Provides robust tools for programmatically managing navigation, leveraging both route and query parameters for seamless transitions.
- **Comprehensive History Management:** Features a powerful history management system that supports back navigation, route replacement, and history clearing functionalities.

## Getting Started

To integrate ParseRoute into your Dart project, simply add it as a dependency in your project's `pubspec.yaml` file:

```yaml
dependencies:
  parse_route: ^<latest_version>
```

Ensure to replace `<latest_version>` with the latest version number of the library.

## Basic Usage

### Setting Up

Begin by importing ParseRoute into your project file:

```dart
import 'package:parse_route/parse_route.dart';
```

### Register Routes

Register your application's routes as follows:

```dart
final parser = ParseRoute();

// Register individual routes with dynamic segments
parser.registerRoute('/user/:id');
// Automatic tracking of nested routes
parser.registerRoute('/profile/followers');
parser.registerRoute('/profile/following');
parser.registerRoute('/profile/edit');
// Wildcard support
parser.registerRoute('/settings/*');
// Query parameter support
parser.registerRoute('/search?foo=bar&baz=qux');
// Dynamic segments can be registered with query parameters
parser.registerRoute('/user/:id?foo=bar');
```

### Route Matching and Navigation

Match a route and navigate through your application with ease:

```dart
final match = parser.matchRoute('/user/123?foo=bar');
if (match != null) {
  // Access matched route and parameters
  print(match.path); // /user/:id
  print(match.parameters); // {id: '123'}
  print(match.urlParameters); // {foo: 'bar'}
}

// Navigate to a route
parser.push('/profile/123');
// Check the current route
print(parser.current.fullPath); // /profile/123
```

### Managing Navigation History

Efficiently manage your navigation history:

```dart
// Navigate through routes
parser.push('/home');
parser.push('/profile/edit');
// Go back to the previous route
parser.pop();
// Verify the current route
print(parser.current.fullPath); // /home
```

## Contribution and Support

We welcome contributions to the ParseRoute library with open arms! If you're interested in contributing, please submit a pull request with your proposed changes. For any questions, suggestions, or issues, feel free to open an issue on our GitHub repository. Your input helps make ParseRoute better.
