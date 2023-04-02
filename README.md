A package that parses your routes, and their parameters.

## Getting started
Add Get to your pubspec.yaml file:

```yaml
dependencies:
  parse_route:
```

Import get in files that it will be used:

```dart
import 'package:parse_route/parse_route.dart';
```

## Usage

```dart
   test('adds a route to the routing tree', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user/:id');
      expect(matcher.matchRoute('user/123'), isNotNull);

      matcher.addRoute('profile/followers');
      expect(matcher.matchRoute('profile/followers'), isNotNull);

      matcher.addRoute('home/feed/photos');
      expect(matcher.matchRoute('home/feed/photos'), isNotNull);
    });

    test('matches a route and extracts parameters', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user/:id');
      final result = matcher.matchRoute('user/123');
      expect(result?.path, equals('/user/:id'));
      expect(result?.parameters, equals({'id': '123'}));
    });

    test('matches a route with url parameters', () {
      final matcher = RouteMatcher();
      matcher.addRoute('/user');
      final result = matcher.matchRoute('user?foo=bar');
      expect(result?.path, equals('/user'));
      expect(result?.urlParameters, equals({'foo': 'bar'}));
    });

    test('matches a route with a root path', () {
      final matcher = RouteMatcher();
      matcher.addRoute('/');
      expect(matcher.matchRoute('/'), isNotNull);
    });

    test('does not match a route that is missing segments', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user/:id');
      expect(matcher.matchRoute('product/abc'), isNull);

      matcher.addRoute('home');
      expect(matcher.matchRoute('product'), isNull);
    });

    test('does not match a route that does not exist', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user/:id');
      expect(matcher.matchRoute('product/abc'), isNull);

      matcher.addRoute('home');
      expect(matcher.matchRoute('settings'), isNull);
    });

    test('does not match a route with a missing segment', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user/settings');
      expect(matcher.matchRoute('user/'), isNull);
    });

    test('does not match a route with more segments', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user');
      expect(matcher.matchRoute('user/settings'), isNull);
    });

    test('does not match a route with a wrong path', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user/:id/comments');
      expect(matcher.matchRoute('user/1234/feed'), isNull);
    });

    test('does match with root an empty path', () {
      final matcher = RouteMatcher();
      expect(matcher.matchRoute('')?.path, '/');
    });

    test('matches a route with query parameters', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user/:id');
      final result = matcher.matchRoute('user/123?foo=bar&baz=qux');
      expect(result?.path, equals('/user/:id'));
      expect(result?.parameters, equals({'id': '123'}));
      expect(result?.urlParameters, equals({'foo': 'bar', 'baz': 'qux'}));
    });

    test('matches a wildcard route', () {
      final matcher = RouteMatcher();
      matcher.addRoute('user/*');
      expect(matcher.matchRoute('user/settings'), isNotNull);
    });
```


