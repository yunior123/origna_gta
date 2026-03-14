encies...
Downloading packages...
  _fe_analyzer_shared 93.0.0 (97.0.0 available)
  analyzer 10.0.1 (11.0.0 available)
  app_links 6.4.1 (7.0.0 available)
  archive 4.0.7 (4.0.9 available)
  build_config 1.2.0 (1.3.0 available)
  build_runner 2.11.0 (2.12.2 available)
  built_value 8.12.3 (8.12.4 available)
  dart_style 3.1.5 (3.1.7 available)
  ffi 2.1.5 (2.2.0 available)
  flutter_riverpod 2.6.1 (3.3.1 available)
  google_sign_in_android 7.2.7 (7.2.9 available)
  google_sign_in_ios 6.2.5 (6.3.0 available)
  google_sign_in_web 1.1.0 (1.1.2 available)
  hooks 1.0.1 (1.0.2 available)
  image 4.7.2 (4.8.0 available)
  image_picker_android 0.8.13+13 (0.8.13+14 available)
  jni 0.14.2 (0.15.2 available)
  json_annotation 4.10.0 (4.11.0 available)
  json_serializable 6.12.0 (6.13.0 available)
> matcher 0.12.19 (was 0.12.18)
  meta 1.17.0 (1.18.1 available)
  native_toolchain_c 0.17.4 (0.17.5 available)
  passkeys 2.8.2 (2.17.4 available)
  patrol 4.1.1 (4.3.0 available)
  patrol_log 0.7.0 (0.7.1 available)
  petitparser 7.0.1 (7.0.2 available)
  posix 6.0.3 (6.5.0 available)
  riverpod 2.6.1 (3.2.1 available)
  sentry 9.12.0 (9.14.0 available)
  sentry_flutter 9.12.0 (9.14.0 available)
  shared_preferences_android 2.4.20 (2.4.21 available)
  sqflite_android 2.4.2+2 (2.4.2+3 available)
> test_api 0.7.10 (was 0.7.9)
  url_launcher_ios 6.3.6 (6.4.1 available)
  uuid 4.5.2 (4.5.3 available)
  video_player 2.11.0 (2.11.1 available)
  video_player_avfoundation 2.9.3 (2.9.4 available)
  win32 5.15.0 (6.0.0 available)
Changed 2 dependencies!
36 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Compiling lib/main.dart for the Web...                          
Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm
Use --no-wasm-dry-run to disable these warnings.
Target dart2js failed: ProcessException: Process exited abnormally with exit code 1:
lib/origna_app.dart:991:10:
Error: The method 'restoreSession' isn't defined for the type 'OrignaBaseAuth'.
 - 'OrignaBaseAuth' is from 'package:orignabase/src/auth.dart' ('../../orignabase/sdks/flutter/orignabase/lib/src/auth.dart').
        .restoreSession(
         ^^^^^^^^^^^^^^
Error: Compilation failed.
  Command: /opt/hostedtoolcache/flutter/stable-3.41.4-x64/bin/cache/dart-sdk/bin/dart compile js --platform-binaries=/opt/hostedtoolcache/flutter/stable-3.41.4-x64/bin/cache/flutter_web_sdk/kernel --invoker=flutter_tool -DENVIRONMENT=dev -DFLUTTER_VERSION=3.41.4 -DFLUTTER_CHANNEL=stable -DFLUTTER_GIT_URL=https://github.com/flutter/flutter.git -DFLUTTER_FRAMEWORK_REVISION=ff37bef603 -DFLUTTER_ENGINE_REVISION=e4b8dca3f1 -DFLUTTER_DART_VERSION=3.11.1 -DFLUTTER_WEB_USE_SKIA=true -DFLUTTER_WEB_USE_SKWASM=false -DFLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/e4b8dca3f1b4ede4c30371002441c88c12187ed6/ --native-null-assertions --no-source-maps --enable-asserts -O1 --no-minify -o /home/runner/work/origna_gta/origna_gta/origna_gta/.dart_tool/flutter_build/075e977c7e5314899d57463fed5c41ea/app.dill --packages=/home/runner/work/origna_gta/origna_gta/origna_gta/.dart_tool/package_config.json --cfe-only /home/runner/work/origna_gta/origna_gta/origna_gta/.dart_tool/flutter_build/075e977c7e5314899d57463fed5c41ea/main.dart
#0      RunResult.throwException (package:flutter_tools/src/base/process.dart:153:5)
#1      _DefaultProcessUtils.run (package:flutter_tools/src/base/process.dart:379:19)
<asynchronous suspension>
#2      Dart2JSTarget.build (package:flutter_tools/src/build_system/targets/web.dart:208:5)
<asynchronous suspension>
#3      _BuildInstance._invokeInternal (package:flutter_tools/src/build_system/build_system.dart:937:9)
<asynchronous suspension>
#4      Future.wait.<anonymous closure> (dart:async/future.dart:546:21)
<asynchronous suspension>
#5      _BuildInstance.invokeTarget (package:flutter_tools/src/build_system/build_system.dart:875:32)
<asynchronous suspension>
#6      Future.wait.<anonymous closure> (dart:async/future.dart:546:21)
<asynchronous suspension>
#7      _BuildInstance.invokeTarget (package:flutter_tools/src/build_system/build_system.dart:875:32)
<asynchronous suspension>
#8      FlutterBuildSystem.build (package:flutter_tools/src/build_system/build_system.dart:684:16)
<asynchronous suspension>
#9      WebBuilder.buildWeb (package:flutter_tools/src/web/compile.dart:107:34)
<asynchronous suspension>
#10     BuildWebCommand.runCommand (package:flutter_tools/src/commands/build_web.dart:300:5)
<asynchronous suspension>
#11     FlutterCommand.run.<anonymous closure> (package:flutter_tools/src/runner/flutter_command.dart:1590:27)
<asynchronous suspension>
#12     AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#13     CommandRunner.runCommand (package:args/command_runner.dart:212:13)
<asynchronous suspension>
#14     FlutterCommandRunner.runCommand.<anonymous closure> (package:flutter_tools/src/runner/flutter_command_runner.dart:496:9)
<asynchronous suspension>
#15     AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#16     FlutterCommandRunner.runCommand (package:flutter_tools/src/runner/flutter_command_runner.dart:431:5)
<asynchronous suspension>
#17     FlutterCommandRunner.run.<anonymous closure> (package:flutter_tools/src/runner/flutter_command_runner.dart:307:33)
<asynchronous suspension>
#18     run.<anonymous closure>.<anonymous closure> (package:flutter_tools/runner.dart:104:11)
<asynchronous suspension>
#19     AppContext.run.<anonymous closure> (package:flutter_tools/src/base/context.dart:154:19)
<asynchronous suspension>
#20     main (package:flutter_tools/executable.dart:103:3)
<asynchronous suspension>

Compiling lib/main.dart for the Web...                             72.5s
Error: Failed to compile application for the Web.
Error: Process completed with exit code 1.