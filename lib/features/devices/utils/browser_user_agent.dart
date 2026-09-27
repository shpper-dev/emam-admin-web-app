// Returns this browser tab's `navigator.userAgent` on web, or an empty
// string on other platforms (there's no browser to ask).
export 'browser_user_agent_stub.dart'
    if (dart.library.html) 'browser_user_agent_web.dart';
