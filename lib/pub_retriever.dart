library dartdoc_runner.pub_retriever;

import 'dart:async';
import 'dart:convert';

import 'package:dartdoc_runner/package.dart';
import 'package:dartdoc_runner/version.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

var _logger = new Logger("pub_retriever");

String _getUrl(int page) =>
    "https://pub.dartlang.org/packages.json?page=$page";

class PubRetriever {
  Set<Package> _currentList = new Set();

  PubRetriever();

  Future<Set<Package>> update() async {
    _logger.info("Retrieving available packages...");
    var page = 1;

    var json;
    do {
      _logger.info("Retrieving page $page");
      json = await http.get(_getUrl(page)).then((r) => JSON.decode(r.body));
      page += 1;
      var pageOfPackages = await Future.wait(json["packages"].map((packageUrl) {
        return http.get(packageUrl).then((r) => JSON.decode(r.body));
      }));
      var packages = pageOfPackages.map((packageMap) {
        return packageMap["versions"].map((version) {
          return new Package(packageMap["name"], new Version(version));
        });
      }).expand((i) => i);
      if (_currentList.containsAll(packages)) {
        break;
      } else {
        _currentList.addAll(packages);
      }
      //} while (json["next"] != null);
    } while (page < 2);

    _logger
        .info("The number of the available packages - ${_currentList.length}");
    return _currentList;
  }
}
