/// createShowDialog returns a Future<bool> __(BuildContext context) function
/// which in turn calls showDialog(context, ...)
///
/// The purpose of this function is to allow calls to eg. ApiConnections to create
/// and return an already defined and filled in Dialog widget.
/// ApiConnections may not have access to a "safe" BuildContext, which is why
/// it will return a function, not just a Dialog widget
///
/// The calling (eg ApiConnections) function can optionally define some action
/// (such as pushing a different route) to be executed by the OK button's
/// onPressed.  Any user choice will pop the Dialog from Navigator
///
/// The calling (eg. ApiConnections) function should pass __ on as a return value
/// The receiving widget of __ should check if __ is null, if not, it should await
/// __ with its (safe) BuildContext.  The widget can optionally test for the
/// true/false return value of __ to further act appropriately to the user choice.
///
/// Use case:
///
/// onOkPressed(BuildContext context) {
///   print("dialog will pop itself, go to divert page afterwards");
///   Navigator.of(context).pushReplacementNamed("/divert")
/// }
///
/// Function postSave() {
///   bool success = trySave();
///   if (success)
///     return null;
///   else
///     return createShowDialog(message: "Saving didn't succeed, want ice cream instead?", errorCode: 999999, ok: onOkPressed, cancellable: true);
/// }
///
/// Function __ = postSave();
/// if (__ != null) {
///   bool wantsIceCream = await __(context);
///   if (wantsIceCream) {
///     giveIceCream();
///   }
/// } else {
///   refreshPage()
/// }
Function createShowDialog({
  String message,
  int errorCode,
  Function ok,
  bool cancellable,
}) {
  return (BuildContext context) async => await showDialog(
        context: context,
        builder: (BuildContext context) => new CuMessageDialog(
              message: message,
              errorCode: errorCode,
              ok: ok,
              cancel: cancellable,
            ),
      );
}

/*
class NewApiConnectionsFunction {

  static String userAgent = 'cuGuardian/${state.version} (${Platform.operatingSystem}) ${Platform.localeName}';

  static Map<String, String> headers = { // successful login will expand the headers with token
    HttpHeaders.userAgentHeader: userAgent,
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.acceptLanguageHeader: 'nb_NO'
  };

  static _okActionOn401(BuildContext context) {
    debugPrint("should send to connecting");
    Navigator.of(context).pushReplacementNamed('/connecting');
  }

  static Future<Function> _request(
      RequestType type,
      String route,
      String parser(http.Response res, dynamic body), {
        String body,
        bool neverTest,
        bool alwaysTest, // alwaysTest == true will prioritize over neverTest == true
      }) async {
    String fullRoute = '${constants.APIBaseUrl}$route';
    debugPrint((body == null) ? 'u.AC.$type: $fullRoute' : 'u.AC.$type: $fullRoute\n             $body');
    http.Response res;
    ApiError ae;
    try {
      if ((TestRequests.TEST && (neverTest == null || !neverTest))
          || (alwaysTest != null && alwaysTest)) {
        res = await TestRequests.createTestResponse(type, route);
      } else {
        // do the actual Api calls
        switch (type) {
          case RequestType.GET:
            res = await http.get(fullRoute, headers: headers);
            break;
          case RequestType.POST:
            res = await http.post(fullRoute, body: body, headers: headers);
            break;
          case RequestType.DELETE:
            res = await http.delete(fullRoute, headers: headers);
            break;
          case RequestType.PATCH:
            res = await http.patch(fullRoute, body: body, headers: headers);
            break;
        }
      }
    } on Exception catch (e) {
      if (await utilities.canReachGoogle()) {
        ae = new ApiError(4040100, 'timeout', Translator.solve('ApiConnections.Timeout'), fullRoute, data: body, res: null, exception: e.toString());
      } else {
        ae = new ApiError(4040101, 'no internet', Translator.solve('NoInternet'), fullRoute, data: body, res: null, exception: e.toString());
      }
    }
    if (ae == null) {
      dynamic resContent;
      if (res.body != null && res.body.length > 0) {
        debugPrint('u.AC.$type: ${res.statusCode} ${res.reasonPhrase} ${res.body}');
        try {
          resContent = json.decode(res.body);
        } on Exception {
          ae = new ApiError(4040102, 'json parse', Translator.solve('ApiConnections.Mismatch'), fullRoute, data: body, res: res, exception: null);
        }
      } else {
        debugPrint('u.AC.$type: ${res.statusCode} ${res.reasonPhrase}');
      }
      if (ae == null) {
        if (res.statusCode == 401) {
          try {
            ErrorResponse ise = ErrorResponse.fromJson(resContent);
            if (ise.message.startsWith('The token has expired')) {
              ae = new ApiError(4040103, 'token expired', Translator.solve('ApiConnections.NotAuthorized'), fullRoute, data: body,
                  res: res,
                  okAction: _okActionOn401,
                  cancelEnabled: true,
                  exception: null);
            } else if (ise.message == '' && type == RequestType.POST) {
              ae = new ApiError(4040104, 'wrong login data', Translator.solve('LoginPage.WrongUserNameOrPasswordOrVerificationCode'), fullRoute, data: body, res: res, exception: null);
            } else {
              ae = new ApiError(4040105, 'not authorized, other', Translator.solve('ApiConnections.NotAuthorized'), fullRoute, data: body,
                  res: res,
                  okAction: _okActionOn401,
                  cancelEnabled: true,
                  exception: null);
            }
          } on Exception catch (e) {
            ae = new ApiError(4040106, 'json parse', Translator.solve('ApiConnections.Mismatch'), fullRoute, data: body, res: res, exception: e.toString());
          }
        }
        if (ae == null) {
          try {
            String result = parser(res, resContent);
            if (result == 'validate') {
              ae = new ApiError(4040107, 'validate', Translator.solve('ApiConnections.Validate'), fullRoute, data: body, res: res, exception: null);
            } else if (result == 'email in use') {
              ae = new ApiError(4040108, 'email in use', Translator.solve('ApiConnections.EmailInUse'), fullRoute, data: body, res: res, exception: null);
            } else if (result != null) {
              ae = new ApiError(4040109, result, Translator.solve('ApiConnections.Mismatch'), fullRoute, data: body, res: res, exception: null);
            }
          } on Exception catch (e) {
            ae = new ApiError(4040110, 'json prop', Translator.solve('ApiConnections.Mismatch'), fullRoute, data: body, res: res, exception: e.toString());
          }
        }
      }
    }
    if (ae != null) {
      ae.debugMessage();
      return messages.createShowDialog(message: ae.translate, errorCode: ae.errorCode, ok: ae.okAction, cancellable: ae.cancelEnabled);
    } else {
      return null;
    }
  }

  /// called by ConnectingPage
  static Future<Function> getRequiredVersion() async {
    String route = '/app_version';
    return _request(RequestType.GET, route, getRequiredVersionResponseHandler, neverTest: true);
  }

  /// called by RegisterPage.
  static Future<Function> postRegister(String name, String usr, String pwd,) async {
    String route = '/register';
    String body = json.encode({
      'name': name,
      'email': usr,
      'password': pwd,
    });
    String _responseHandler(http.Response res, dynamic body) {
      return postRegisterResponseHandler(res, body, usr, pwd);
    }
    return _request(RequestType.POST, route, _responseHandler, body: body, neverTest: false);
  }
  /// called by ConnectingPage and LoginPage
  static Future<Function> postLogin(String usr, String pwd, [String code,]) async {
    String route = '/auth';
    String body = json.encode({
      'email': usr,
      'password': pwd,
      'verificationCode': code ?? '',
    });
    String _responseHandler(http.Response res, dynamic body) {
      return postLoginResponseHandler(res, body, usr, pwd);
    }
    return _request(RequestType.POST, route, _responseHandler, body: body, neverTest: true);
  }

  /// called by LoggingInPage with freshly gotten Firebase token
  static Future<Function> postFirebaseToken(String token) async {
    String route = '/store-push-notification-token';
    String body = json.encode({
      'registrationToken': token,
      'operatingSystem': state.deviceModel,
      'operatingSystemVersion': state.deviceOS,
    });
    return _request(RequestType.POST, route, postFirebaseTokenResponseHandler, body: body, neverTest: false);
  }

  /// called by LoggingInPage after successfully updating firebase token DB
  static Future<Function> getDevices() async {
    String route = '/devices';
    return _request(RequestType.GET, route, getDevicesResponseHandler, neverTest: false);
  }

  /// called by DashboardPage, UserTab, and DependantCard (two latter for refreshes after saves)
  static Future<Function> getDashboard() async {
    String route = '/dashboard';
    return _request(RequestType.GET, route, getDashboardResponseHandler, neverTest: false);
  }

  /// called by UserTab
  static Future<Function> postDependant(Dependant dependant) async {
    String route = '/dependants';
    String body = json.encode(dependant.toJson());
    return _request(RequestType.POST, route, postDependantResponseHandler, body: body, neverTest: false);
  }

  /// called by DependantPage and UserTab (latter for refreshes after saves)
  static Future<Function> getDependant(String dependantId) async {
    String route = '/dependants/$dependantId';
    return _request(RequestType.GET, route, getDependantResponseHandler, neverTest: false);
  }

  /// called by UserTab
  static Future<Function> patchDependant(Dependant dependant) async { // TODO: ain't working yet?
    String route = '/dependants/${dependant.dependantId}';
    String body = json.encode(dependant.toJson());
    return _request(RequestType.PATCH, route, patchDependantResponseHandler, body: body, neverTest: false);
  }

  /// called by DependantCard
  static Future<Function> deleteDependant(String dependantId) async {
    String route = '/dependants/$dependantId';
    return _request(RequestType.DELETE, route, deleteDependantResponseHandler, neverTest: false);
  }

  /// called by ActivityPage and StepsPage
  static Future<Function> getSteps(String dependantId) async {
    String route = '/dependants/$dependantId/steps'; // TODO: for getSteps, steps route must be implemented in API
    return _request(RequestType.GET, route, getStepsResponseHandler, alwaysTest: true);
  }

  /// called by ActivityPage and StepsPage
  static Future<Function> getPulse(String dependantId) async {
    String route = '/dependants/$dependantId/pulse'; // TODO: for getSteps, steps route must be implemented in API, swap route
    return _request(RequestType.GET, route, getPulseResponseHandler, alwaysTest: true);
  }

}
*/

