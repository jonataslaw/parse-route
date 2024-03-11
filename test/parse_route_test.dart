import 'package:parse_route/parse_route.dart';
import 'package:test/test.dart';

void main() {
  group('RouteMatcher', () {
    test('adds a route to the routing tree', () {
      final parser = ParseRoute();
      parser.registerRouter('user/:id');
      expect(parser.matchRoute('user/123'), isNotNull);

      parser.registerRouter('profile/followers');
      expect(parser.matchRoute('profile/followers'), isNotNull);

      parser.registerRouter('home/feed/photos');
      expect(parser.matchRoute('home/feed/photos'), isNotNull);
    });

    test('matches a route and extracts parameters', () {
      final parser = ParseRoute();
      parser.registerRouter('/user/:id');
      final result = parser.matchRoute('/user/123');
      expect(result?.path, equals('/user/:id'));
      expect(result?.parameters, equals({'id': '123'}));
    });

    test('matches a route with url parameters', () {
      final parser = ParseRoute();
      parser.registerRouter('/user');
      final result = parser.matchRoute('user?foo=bar');
      expect(result?.path, equals('/user'));
      expect(result?.urlParameters, equals({'foo': 'bar'}));
    });

    test('matches a route with a root path', () {
      final parser = ParseRoute();
      parser.registerRouter('/');
      expect(parser.matchRoute('/'), isNotNull);
    });

    test('does not match a route that is missing segments', () {
      final parser = ParseRoute();
      parser.registerRouter('user/:id');
      expect(parser.matchRoute('product/abc'), isNull);

      parser.registerRouter('home');
      expect(parser.matchRoute('product'), isNull);
    });

    test('does not match a route that does not exist', () {
      final parser = ParseRoute();
      parser.registerRouter('user/:id');
      expect(parser.matchRoute('product/abc'), isNull);

      parser.registerRouter('home');
      expect(parser.matchRoute('settings'), isNull);
    });

    test('does not match a route with a missing segment', () {
      final parser = ParseRoute();
      parser.registerRouter('user/settings');
      expect(parser.matchRoute('user'), isNull);
    });

    test('does not match a route with more segments', () {
      final parser = ParseRoute();
      parser.registerRouter('user');
      expect(parser.matchRoute('user/settings'), isNull);
    });

    test('does not match a route with a wrong path', () {
      final parser = ParseRoute();
      parser.registerRouter('user/:id/comments');
      expect(parser.matchRoute('user/1234/feed'), isNull);
    });

    test('matches a route with query parameters', () {
      final parser = ParseRoute();
      parser.registerRouter('/user/:id');
      final result = parser.matchRoute('/user/123?foo=bar&baz=qux');
      expect(result?.path, equals('/user/:id'));
      expect(result?.parameters, equals({'id': '123'}));
      expect(result?.urlParameters, equals({'foo': 'bar', 'baz': 'qux'}));
    });

    test('matches a wildcard route', () {
      final parser = ParseRoute();
      parser.registerRouter('user/*');
      expect(parser.matchRoute('user/settings'), isNotNull);
    });
  });
  group('Navigator', () {
    late ParseRoute parser;

    setUp(() {
      parser = ParseRoute();
    });

    group('Route Registration', () {
      setUp(() {
        parser = ParseRoute();
      });
      test('registers a route', () {
        parser.registerRouter('/home');
        expect(parser.isRegistered('/home'), isTrue);
      });

      test('registers multiple routes', () {
        parser.registerRouter('/home');
        parser.registerRouter('/profile');
        parser.registerRouter('/settings');
        expect(parser.isRegistered('/home'), isTrue);
        expect(parser.isRegistered('/profile'), isTrue);
        expect(parser.isRegistered('/settings'), isTrue);
      });

      test('registers nested routes', () {
        parser.registerRouter('/home');
        parser.registerRouter('/profile');
        parser.registerRouter('/profile/edit');
        parser.registerRouter('/profile/feed');
        expect(parser.isRegistered('/home'), isTrue);
        expect(parser.isRegistered('/profile'), isTrue);
        final value = parser.matchRoute('/profile/edit');
        print(value);
        expect(parser.isRegistered('/profile/edit'), isTrue);
        // expect(parser.isRegistered('/profile/feed'), isTrue);
      });
    });

    group('Navigation', () {
      setUp(() {
        parser.registerRouter('/home');
        parser.registerRouter('/profile');
        parser.registerRouter('/profile/edit');
        parser.registerRouter('/profile/feed');
        parser.registerRouter('/profile/:id');
        parser.registerRouter('/settings');
      });

      test('navigates to a route', () {
        parser.push('/home');
        expect(parser.current.fullPath, equals('/home'));
      });

      test('navigates to a route with parameters', () {
        parser.push('/profile/123');
        expect(parser.current.fullPath, equals('/profile/123'));
        expect(parser.current.parameters, equals({'id': '123'}));
      });

      test('navigates to a route with query parameters', () {
        parser.push('/profile/123?foo=bar&baz=qux');
        expect(parser.current.cleanPath, equals('/profile/123'));
        expect(parser.current.parameters, equals({'id': '123'}));
        expect(
            parser.current.urlParameters, equals({'foo': 'bar', 'baz': 'qux'}));
      });

      test('navigates to a route with url parameters', () {
        parser.push('/profile?foo=bar');
        expect(parser.current.cleanPath, equals('/profile'));
        expect(parser.current.urlParameters, equals({'foo': 'bar'}));
      });

      test('navigates to a route with a root path', () {
        parser.registerRouter('/');
        parser.push('/');
        expect(parser.current.fullPath, equals('/'));
      });

      test('navigates to multiple routes', () {
        parser.push('/home');
        expect(parser.current.fullPath, equals('/home'));

        parser.push('/profile/edit');
        expect(parser.current.fullPath, equals('/profile/edit'));

        parser.push('/profile/123');
        expect(parser.current.fullPath, equals('/profile/123'));
        expect(parser.current.parameters, equals({'id': '123'}));

        parser.push('/profile/feed');
        expect(parser.current.fullPath, equals('/profile/feed'));
      });
    });

    group('Route Retrieval', () {
      setUp(() {
        parser.registerRouter('/home');
        parser.registerRouter('/profile');
        parser.registerRouter('/profile/edit');
        parser.registerRouter('/profile/feed');
        parser.registerRouter('/profile/:id');
        parser.registerRouter('/settings/profile/name');
      });

      test('getRoutesFrom returns all routes from a base path', () {
        expect(
            parser.getRoutesFrom('/'),
            equals([
              '/home',
              '/profile',
              '/profile/edit',
              '/profile/feed',
              '/profile/:id',
              '/settings/profile/name',
            ]));

        expect(
            parser.getRoutesFrom('/profile'),
            equals([
              '/profile',
              '/profile/edit',
              '/profile/feed',
              '/profile/:id',
            ]));

        expect(parser.getRoutesFrom('/settings/profile/name'),
            equals(['/settings/profile/name']));
      });

      test('getSubRoutesFrom returns subroutes from a base path', () {
        expect(parser.getSubRoutesFrom('/profile'),
            equals(['/profile/edit', '/profile/feed', '/profile/:id']));
      });

      test('getRoutesFromCurrent returns routes from the current route', () {
        parser.push('/home');
        expect(parser.getRoutesFromCurrent(), equals(['/home']));

        parser.push('/settings/profile/name');
        expect(
            parser.getRoutesFromCurrent(), equals(['/settings/profile/name']));

        parser.push('/profile/edit');
        print(
            "getRoutesFromCurrent result: ${parser.getRoutesFromCurrent().join(', ')}");
        expect(
            parser.getRoutesFromCurrent(),
            equals([
              '/profile',
              '/profile/edit',
              '/profile/feed',
              '/profile/:id'
            ]));
      });

      test('getSubRoutesFromCurrent returns subroutes from the current route',
          () {
        parser.push('/profile');
        expect(parser.getSubRoutesFromCurrent(),
            equals(['/profile/edit', '/profile/feed', '/profile/:id']));

        parser.push('/profile/123');
        expect(parser.getSubRoutesFromCurrent(),
            equals(['/profile/edit', '/profile/feed', '/profile/:id']));
      });
    });

    group('History Management', () {
      setUp(() {
        parser.registerRouter('/home');
        parser.registerRouter('/profile');
        parser.registerRouter('/profile/edit');
        parser.registerRouter('/profile/feed');
        parser.registerRouter('/profile/:id');
        parser.registerRouter('/settings');
      });

      test('pop removes the last route from the history', () {
        parser.push('/home');
        parser.push('/profile/edit');
        parser.push('/profile/123');

        parser.pop();
        expect(parser.current.fullPath, equals('/profile/edit'));

        parser.pop();
        expect(parser.current.fullPath, equals('/home'));
      });

      test('replaceLast replaces the last route in the history', () {
        parser.push('/home');
        parser.push('/profile/edit');

        parser.replaceLast('/settings');
        expect(parser.current.fullPath, equals('/settings'));
      });

      test('clearHistory removes all routes from the history', () {
        parser.push('/home');
        parser.push('/profile/edit');
        parser.push('/profile/123');

        parser.clearHistory();
        expect(() => parser.current, throwsStateError);
      });

      test('getLastVisitedSubroute returns the last visited subroute', () {
        parser.push('/home');
        parser.push('/profile/edit');
        parser.push('/profile/123');

        expect(
            parser.getLastVisitedSubroute('/profile'), equals('/profile/123'));

        parser.pop();
        expect(
            parser.getLastVisitedSubroute('/profile'), equals('/profile/edit'));
      });
    });

    group('Error Handling', () {
      test('returns null when matching an unregistered route', () {
        expect(parser.matchRoute('/unknown'), isNull);
      });

      test('returns false when checking if an unregistered route is registered',
          () {
        expect(parser.isRegistered('/unknown'), isFalse);
      });

      test(
          'returns an empty list when getting routes from an unregistered base path',
          () {
        expect(parser.getRoutesFrom('/unknown'), isEmpty);
      });

      test(
          'returns an empty list when getting subroutes from an unregistered base path',
          () {
        expect(parser.getSubRoutesFrom('/unknown'), isEmpty);
      });
    });
  });
}
