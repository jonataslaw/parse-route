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

    test('matches a route with multiple parameters', () {
      final parser = ParseRoute();
      parser.registerRouter('/user/:id/comments/:commentId');
      final result = parser.matchRoute('/user/123/comments/456');
      expect(result?.path, equals('/user/:id/comments/:commentId'));
      expect(result?.parameters, equals({'id': '123', 'commentId': '456'}));
    });

    test('matches a wildcard route', () {
      final parser = ParseRoute();
      parser.registerRouter('user/*');
      expect(parser.matchRoute('user/settings'), isNotNull);
    });

    test('MatchResult toString method provides correct string representation',
        () {
      final parser = ParseRoute();
      parser.registerRouter('/user/:id');
      final matchResult = parser.matchRoute('/user/123?query=value');
      assert(matchResult != null);
      final expectedString =
          'MatchResult(path: /user/:id, cleanPath: /user/123, parameters: {id: 123}, urlParameters: {query: value})';

      expect(matchResult.toString(), equals(expectedString));
    });

    test('HistoryEntry toString method provides correct string representation',
        () {
      final parseRoute = ParseRoute();
      parseRoute.registerRouter('/user/:id');
      parseRoute.push('/user/123?query=value');
      final historyEntry = parseRoute.current;
      final expectedString =
          'HistoryEntry(path: /user/:id, parameters: {id: 123}, urlParameters: {query: value}, fullPath: /user/123?query=value, cleanPath: /user/123)';

      expect(historyEntry.toString(), equals(expectedString));
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
        expect(parser.isRegistered('/profile/feed'), isTrue);
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

      test('Test special handling for deeply nested routes', () {
        // Initialize ParseRoute
        final parseRoute = ParseRoute();

        // Register routes
        parseRoute.registerRouter('/product');
        parseRoute.registerRouter('/product/detail');

        // Simulate navigating to the deeply nested route
        parseRoute.push('/product/detail');

        // Call getRoutesFromCurrent to trigger the special handling
        final routes = parseRoute.getRoutesFromCurrent();

        // Verify the output matches expected behavior
        expect(routes, equals(['/product/detail']));
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
        parser.push('/settings');

        expect(
            parser.getLastVisitedSubroute('/profile'), equals('/profile/123'));

        parser.pop();
        parser.pop();
        parser.push('/settings');
        expect(
            parser.getLastVisitedSubroute('/profile'), equals('/profile/edit'));
      });

      test('getHistoryDebug returns the history as a string', () {
        parser.push('/home');
        parser.push('/profile/edit');
        parser.push('/profile/123');
        parser.push('/settings');

        expect(parser.getHistoryDebug(),
            equals('/home -> /profile/edit -> /profile/123 -> /settings'));
      });
    });

    group('ParseRoute with RouteListener', () {
      late ParseRoute parser;

      setUp(() {
        parser = ParseRoute();
        parser.registerRouter('/');
        parser.registerRouter('/home');
        parser.registerRouter('/home/profile');
        parser.registerRouter('/home/settings');
        parser.registerRouter('/home/user');
        parser.registerRouter('/home/user/:id');
        parser.registerRouter('/about');
        parser.registerRouter('/about/team');
      });

      test('root listener receives all changes', () {
        final changes = <String>[];
        final types = <RouteChangeType>[];
        parser.addListener('/', (newRoute, oldRoute, type) {
          changes.add(newRoute.fullPath);
          types.add(type);
        });

        parser.push('/home');
        parser.push('/home/profile');
        parser.pop();
        parser.replaceLast('/about');

        expect(changes, equals(['/home', '/home/profile', '/home', '/about']));
        expect(
            types,
            equals([
              RouteChangeType.push,
              RouteChangeType.push,
              RouteChangeType.pop,
              RouteChangeType.replace
            ]));
      });

      test('specific listener only receives relevant changes', () {
        final homeChanges = <String>[];
        parser.addListener('/home', (newRoute, oldRoute, type) {
          homeChanges.add(newRoute.fullPath);
        });

        parser.push('/home');
        parser.push('/home/profile');
        parser.push('/home/settings');
        parser.push('/about');
        parser.pop();

        expect(
            homeChanges,
            equals([
              '/home',
              '/home/profile',
              '/home/settings',
              '/home/settings'
            ]));
      });

      test('more specific listener overrides less specific', () {
        final homeChanges = <String>[];
        final profileChanges = <String>[];

        parser.addListener('/home', (newRoute, oldRoute, type) {
          homeChanges.add(newRoute.fullPath);
        });
        parser.addListener('/home/profile', (newRoute, oldRoute, type) {
          profileChanges.add(newRoute.fullPath);
        });

        parser.push('/home');
        parser.push('/home/profile');
        parser.push('/home/settings');

        expect(homeChanges, equals(['/home', '/home/settings']));
        expect(profileChanges, equals(['/home/profile']));
      });

       test('listener receives correct routes with parameters', () {
        final oldRoutes = <String?>[];
        parser.addListener('/', (newRoute, oldRoute, type) {
          oldRoutes.add(oldRoute?.fullPath);
        });

        parser.push('/home');
        parser.push('/about');
        parser.pop();

        expect(oldRoutes, equals([null, '/home', '/about']));
      });

      test('listenToAll receives all changes regardless of path', () {
        final allChanges = <String>[];
        parser.addListener('/', (newRoute, oldRoute, type) {
          allChanges.add(newRoute.fullPath);
        }, listenToAll: true);

        parser.push('/home');
        parser.push('/home/profile');
        parser.push('/about');

        expect(allChanges, equals(['/home', '/home/profile', '/about']));
      });

      test('removeListener stops notifications', () {
        final changes = <String>[];
        parser.addListener('/home', (newRoute, oldRoute, type) {
          changes.add(newRoute.fullPath);
        });

        parser.push('/home');
        parser.push('/home/profile');

        parser.removeListener('/home');

        parser.push('/home/settings');

        expect(changes, equals(['/home', '/home/profile']));
      });

      test('listeners receive correct old routes', () {
        final oldRoutes = <String?>[];
        parser.addListener('/', (newRoute, oldRoute, type) {
          oldRoutes.add(oldRoute?.fullPath);
        });

        parser.push('/home');
        parser.push('/about');
        parser.pop();

        expect(oldRoutes, equals([null, '/home', '/about']));
      });

      test('listeners receive correct RouteChangeType', () {
        final changeTypes = <RouteChangeType>[];
        parser.addListener('/', (newRoute, oldRoute, type) {
          changeTypes.add(type);
        });

        parser.push('/home');
        parser.push('/about');
        parser.pop();
        parser.replaceLast('/home/profile');

        expect(
            changeTypes,
            equals([
              RouteChangeType.push,
              RouteChangeType.push,
              RouteChangeType.pop,
              RouteChangeType.replace
            ]));
      });

      test('multiple listeners with different paths', () {
        final homeChanges = <String>[];
        final aboutChanges = <String>[];

        parser.addListener('/home', (newRoute, oldRoute, type) {
          homeChanges.add(newRoute.fullPath);
        });
        parser.addListener('/about', (newRoute, oldRoute, type) {
          aboutChanges.add(newRoute.fullPath);
        });

        parser.push('/home');
        parser.push('/home/profile');
        parser.push('/about');
        parser.push('/about/team');

        expect(homeChanges, equals(['/home', '/home/profile']));
        expect(aboutChanges, equals(['/about', '/about/team']));
      });

      test('listener receives correct parameters', () {
        Map<String, String>? capturedParams;
        parser.registerRouter('/user/:id');
        parser.addListener('/user', (newRoute, oldRoute, type) {
          capturedParams = newRoute.parameters;
        });

        parser.push('/user/123');

        expect(capturedParams, equals({'id': '123'}));
      });

      test('listener receives correct URL parameters', () {
        Map<String, String>? capturedUrlParams;
        parser.addListener('/home', (newRoute, oldRoute, type) {
          capturedUrlParams = newRoute.urlParameters;
        });

        parser.push('/home?key=value&foo=bar');

        expect(capturedUrlParams, equals({'key': 'value', 'foo': 'bar'}));
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

    group('RouteMatcher - Complex Routes', () {
      late ParseRoute parser;

      setUp(() {
        parser = ParseRoute();
        parser.registerRouter('/shop/items/list/view/detail');
        parser.registerRouter('/user/profile/settings/account/security');
        parser.registerRouter('/admin/dashboard/reports/finance/summary');
      });

      test('matches a deeply nested route', () {
        final result = parser.matchRoute('/shop/items/list/view/detail');
        expect(result, isNotNull);
        expect(result?.path, equals('/shop/items/list/view/detail'));
      });

      test('matches a route with deep nesting and extracts parameters', () {
        parser.registerRouter('/project/:projectId/task/:taskId/detail');
        final result = parser.matchRoute('/project/42/task/108/detail');
        expect(
            result?.parameters, equals({'projectId': '42', 'taskId': '108'}));
      });

      test(
          'matches a route with deep nesting and extracts parameters and url parameters',
          () {
        parser.registerRouter('/project/:projectId/task/:taskId/detail');
        final result =
            parser.matchRoute('/project/42/task/108/detail?foo=bar&baz=qux');
        expect(
            result?.parameters, equals({'projectId': '42', 'taskId': '108'}));
        expect(result?.urlParameters, equals({'foo': 'bar', 'baz': 'qux'}));
      });

      test(
          'does not match a route when a segment is missing in a deeply nested route',
          () {
        expect(parser.matchRoute('/shop/items/list/view'), isNull);
      });

      test(
          'matches a route with multiple url parameters in a deeply nested route',
          () {
        final result = parser.matchRoute(
            '/user/profile/settings/account/security?foo=bar&baz=qux');
        expect(result?.path, equals('/user/profile/settings/account/security'));
        expect(result?.urlParameters, equals({'foo': 'bar', 'baz': 'qux'}));
      });

      test('does not match a route with incorrect ordering of segments', () {
        expect(parser.matchRoute('/admin/dashboard/finance/reports/summary'),
            isNull);
      });
    });
  });
}
