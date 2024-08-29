library parse_route;

/// A class representing the result of a route matching operation.
class MatchResult {
  /// Route found that matches the result
  final String path;

  /// The clean path of the route
  /// e.g. '/profile/123?foo=bar&baz=qux' will be '/profile/123'
  final String cleanPath;

  /// Route parameters eg: adding 'user/:id' the match result for 'user/123' will be: {id: 123}
  final Map<String, String> parameters;

  /// Route url parameters eg: adding 'user' the match result for 'user?foo=bar' will be: {foo: bar}
  final Map<String, String> urlParameters;

  /// The route definition that matched the result
  final RouteDefinition routeDefinition;

  MatchResult(
    this.path,
    this.parameters, {
    required this.cleanPath,
    required this.routeDefinition,
    this.urlParameters = const {},
  });

  @override
  String toString() =>
      'MatchResult(path: $path, cleanPath: $cleanPath, parameters: $parameters, urlParameters: $urlParameters)';
}

/// Defines a route with a pattern, segments for matching, and support for wildcards.
class RouteDefinition {
  /// The route pattern
  /// e.g. '/user/:id'
  /// e.g. '/user/*'
  /// e.g. '/user?foo=bar'
  /// e.g. '/user/:id?foo=bar'
  final String pattern;

  /// The segments of the route pattern
  /// e.g. '/user/:id' will be ['user', ':id']
  final List<String> segments;

  /// Whether the route pattern contains a wildcard
  /// e.g. '/user/*' will be true
  final bool isWildcard;

  RouteDefinition(this.pattern)
      : segments = _parsePath(pattern),
        isWildcard = pattern.contains('*');

  static List<String> _parsePath(String path) => path
      .split('/')
      .where((segment) => segment.isNotEmpty && segment != '*')
      .toList();

  /// Checks if a given list of path segments matches this route definition.
  bool matches(List<String> pathSegments) {
    if (isWildcard) {
      return _matchesWithWildcard(pathSegments);
    } else {
      return _matchesExactly(pathSegments);
    }
  }

  bool _matchesWithWildcard(List<String> pathSegments) {
    // For wildcard, only match the prefix before the wildcard
    for (int i = 0; i < segments.length; i++) {
      if (pathSegments.length < i || segments[i] != pathSegments[i]) {
        return false;
      }
    }
    return true;
  }

  bool _matchesExactly(List<String> pathSegments) {
    if (segments.length != pathSegments.length) return false;

    for (int i = 0; i < segments.length; i++) {
      final isParam = segments[i].startsWith(':');
      if (!isParam && segments[i] != pathSegments[i]) {
        return false;
      }
    }
    return true;
  }

  /// Extracts route parameters from the path segments.
  Map<String, String> extractParameters(List<String> pathSegments) {
    final parameters = <String, String>{};
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].startsWith(':')) {
        parameters[segments[i].substring(1)] = pathSegments[i];
      }
    }
    return parameters;
  }
}

/// A class responsible for matching routes against registered route definitions.
/// It also keeps track of the registered routes.
/// It is used by the [ParseRoute] class.
class _RouteMatcher {
  final List<RouteDefinition> _routes = [];

  bool isRegistered(String path) {
    return matchRoute(path) != null;
  }

  void addRoute(String path) {
    final definition = RouteDefinition(path);
    _routes.add(definition);
  }

  MatchResult? matchRoute(String path) {
    final uri = Uri.parse(path);
    final pathSegments = RouteDefinition._parsePath(uri.path);

    for (var route in _routes) {
      if (route.matches(pathSegments)) {
        final parameters = route.extractParameters(pathSegments);
        final urlParameters = uri.queryParameters;
        return MatchResult(
          route.pattern,
          parameters,
          urlParameters: urlParameters,
          cleanPath: uri.path,
          routeDefinition: route,
        );
      }
    }

    return null; // No matching route found
  }
}

/// A class representing the navigation history.
class _NavigationHistory {
  final List<HistoryEntry> _history = [];

  void push(HistoryEntry path) {
    _history.add(path);
  }

  HistoryEntry? pop() {
    if (_history.isNotEmpty) {
      return _history.removeLast();
    }
    return null;
  }

  void replaceLast(HistoryEntry path) {
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
    _history.add(path);
  }

  void clear() {
    _history.clear();
  }

  HistoryEntry get current => _history.last;

  bool isEmpty() => _history.isEmpty;

  String? getLastVisitedSubroute(String basePath) {
    for (var path in _history.reversed) {
      if (path.fullPath.startsWith('$basePath/')) {
        return path.fullPath;
      }
    }
    return null;
  }

  @override
  String toString() => _history.map((e) {
        return e.fullPath;
      }).join(' -> ');
}

/// A class representing a history entry.
class HistoryEntry {
  /// The full path of the route
  /// e.g. '/user/123'
  /// e.g. '/user/123?foo=bar&baz=qux'
  final String fullPath;

  /// The path of the route
  /// e.g. '/user/:id'
  final String path;

  /// The parameters of the route
  /// e.g. '/user/:id' with '/user/123' will be {id: 123}
  final Map<String, String> parameters;

  /// The url parameters of the route
  /// e.g. '/user' with '/user?foo=bar' will be {foo: bar}
  final Map<String, String> urlParameters;

  /// The clean path of the route
  /// e.g. '/profile/123?foo=bar&baz=qux' will be '/profile/123'
  final String cleanPath;

  HistoryEntry({
    required this.path,
    required this.parameters,
    required this.fullPath,
    required this.cleanPath,
    required this.urlParameters,
  });

  @override
  String toString() =>
      'HistoryEntry(path: $path, parameters: $parameters, urlParameters: $urlParameters, fullPath: $fullPath, cleanPath: $cleanPath)';
}

typedef RouteChangeCallback = void Function(
    HistoryEntry newRoute, HistoryEntry? oldRoute, RouteChangeType type);

class RouteListener {
  final String path;
  final RouteChangeCallback callback;
  final bool listenToAll;

  RouteListener(this.path, this.callback, {this.listenToAll = false});
}

class _RouterNotifier {
  final List<RouteListener> _listeners = [];

  void addListener(String path, RouteChangeCallback callback,
      {bool listenToAll = false}) {
    _listeners.add(RouteListener(path, callback, listenToAll: listenToAll));
  }

  void removeListener(String path) {
    _listeners.removeWhere((listener) => listener.path == path);
  }

  void notifyListeners(
      HistoryEntry newRoute, HistoryEntry? oldRoute, RouteChangeType type) {
    for (var listener in _listeners) {
      if (listener.listenToAll) {
        listener.callback(newRoute, oldRoute, type);
      } else if (newRoute.fullPath.startsWith(listener.path)) {
        bool shouldNotify = true;
        for (var otherListener in _listeners) {
          if (otherListener != listener &&
              newRoute.fullPath.startsWith(otherListener.path) &&
              otherListener.path.length > listener.path.length) {
            shouldNotify = false;
            break;
          }
        }
        if (shouldNotify) {
          listener.callback(newRoute, oldRoute, type);
        }
      }
    }
  }
}

enum RouteChangeType { push, pop, replace }

class ParseRoute {
  final _RouteMatcher _registry = _RouteMatcher();
  final _NavigationHistory _history = _NavigationHistory();
  final _RouterNotifier _notifier = _RouterNotifier();

  /// Registers a new route.
  /// The path can contain parameters, e.g. '/user/:id'.
  /// The path can also contain wildcards, e.g. '/user/*'.
  /// The path can also contain query parameters, e.g. '/user?foo=bar'.
  void registerRouter(String path) {
    _registry.addRoute(path);
  }

  /// Adds a listener to the router.
  /// The listener will be called whenever the route changes.
  /// If [listenToAll] is true, the listener will be called for all routes.
  /// If [listenToAll] is false, the listener will be called only for the specified route.
  /// The [callback] function will be called with the new route and the old route.
  /// The old route will be null if there is no previous route.
  void addListener(String path, RouteChangeCallback callback,
      {bool listenToAll = false}) {
    _notifier.addListener(path, callback, listenToAll: listenToAll);
  }

  /// Removes a listener from the router.
  /// The listener will no longer be called when the route changes.
  void removeListener(String path) {
    _notifier.removeListener(path);
  }

  /// Pushes a new route to the navigation stack.
  void push(String path) {
    final oldRoute = _oldRoute;
    final register =
        _registry.matchRoute(path); // Check if the route is registered
    if (register != null) {
      _history.push(HistoryEntry(
        path: register.path,
        parameters: register.parameters,
        urlParameters: register.urlParameters,
        fullPath: path,
        cleanPath: register.cleanPath,
      ));
    }
    _notifier.notifyListeners(_history.current, oldRoute, RouteChangeType.push);
  }

  /// Pops the last route from the navigation stack.
  void pop() {
    final oldRoute = _oldRoute;
    _history.pop();
    if (_history.current != oldRoute) {
      _notifier.notifyListeners(
          _history.current, oldRoute, RouteChangeType.pop);
    }
  }

  HistoryEntry? get _oldRoute => _history.isEmpty() ? null : _history.current;

  /// Replaces the last route with a new route.
  void replaceLast(String path) {
    final oldRoute = _oldRoute;
    final register = _registry.matchRoute(path);
    if (register != null) {
      _history.replaceLast(HistoryEntry(
        path: register.path,
        parameters: register.parameters,
        urlParameters: register.urlParameters,
        fullPath: path,
        cleanPath: register.cleanPath,
      ));
    }
    _notifier.notifyListeners(
        _history.current, oldRoute, RouteChangeType.replace);
  }

  /// Clears the navigation history
  void clearHistory() {
    _history.clear();
  }

  /// Returns the current route.
  HistoryEntry get current => _history.current;

  /// Matches a route against the registered routes.
  /// Returns a [MatchResult] if a route is found, otherwise returns null.
  MatchResult? matchRoute(String path) {
    return _registry.matchRoute(path);
  }

  /// Returns a list of all registered routes
  bool isRegistered(String path) {
    return _registry.isRegistered(path);
  }

  /// Returns the last visited subroute from the given base path
  String? getLastVisitedSubroute(String basePath) {
    return _history.getLastVisitedSubroute(basePath);
  }

  /// Returns a list of routes from the given base path
  /// If the base path is a subroute, it will return the parent route and its siblings
  /// If the base path is a top-level route, it will return the current route and its children
  List<String> getRoutesFrom(String basePath) {
    final Set<String> matchedRoutes = {};
    for (var route in _registry._routes) {
      if (basePath.endsWith('/')) {
        basePath = basePath.substring(0, basePath.length - 1);
      }

      if ("${route.pattern}/".startsWith('$basePath/')) {
        matchedRoutes.add(route.pattern);
      }
    }
    return matchedRoutes.toList();
  }

  /// Returns a list of subroutes from the given base path
  /// If the base path is a subroute, it will return its siblings
  /// If the base path is a top-level route, it will return its children
  List<String> getSubRoutesFrom(String basePath) {
    final Set<String> matchedSubRoutes = {};
    for (var route in _registry._routes) {
      if (route.pattern.startsWith('$basePath/') && route.pattern != basePath) {
        matchedSubRoutes.add(route.pattern);
      }
    }
    return matchedSubRoutes.toList();
  }

  /// Returns a list of routes from the current route
  /// If the current route is a subroute, it will return the parent route and its siblings
  /// If the current route is a top-level route, it will return the current route and its children
  List<String> getRoutesFromCurrent() {
    final currentPath = _history.current.fullPath;

    // Check if the current route is deeply nested by counting the slashes
    final slashCount = currentPath.codeUnits
        .where((char) => char == 47)
        .length; // 47 is the ASCII code for '/'

    if (slashCount <= 1) {
      // For root or top-level routes, return the current route only
      return [currentPath];
    } else {
      // For deeply nested routes, determine if we need to include siblings or just the current route
      final parentPath = currentPath.substring(0, currentPath.lastIndexOf('/'));
      final List<String> allRoutesFromParent = getRoutesFrom(parentPath);

      if (allRoutesFromParent.contains(currentPath) &&
          allRoutesFromParent.length == 1) {
        // If the current path is the only route within its parent, return just the current path
        return [currentPath];
      } else {
        // For nested routes with siblings, include the parent route, the current route, and any siblings
        final List<String> relevantRoutes = allRoutesFromParent.where((route) {
          return route == parentPath || route.startsWith('$parentPath/');
        }).toList();

        // Special handling for cases where only the deeply nested route is expected
        if (relevantRoutes.contains(currentPath) &&
            relevantRoutes.length == 2 &&
            parentPath != '/') {
          return [currentPath];
        }

        return relevantRoutes;
      }
    }
  }

  /// Returns a list of subroutes from the current route
  /// If the current route is a subroute, it will return its siblings
  /// If the current route is a top-level route, it will return its children
  List<String> getSubRoutesFromCurrent() {
    final currentPath = _history.current.fullPath;

    // Directly use getSubRoutesFrom with the current path
    final subRoutes = getSubRoutesFrom(currentPath);
    // Ensure that if we're at a specific subroute, it still returns its siblings
    if (subRoutes.isEmpty && currentPath.contains('/')) {
      final basePath = currentPath.substring(0, currentPath.lastIndexOf('/'));
      return getSubRoutesFrom(basePath);
    }

    return subRoutes;
  }

  /// Returns the navigation history
  String getHistoryDebug() {
    return _history.toString();
  }
}
