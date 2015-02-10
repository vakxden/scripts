
var app = angular.module("portal", []);

app.controller("build", function($scope, $http) {
  $http.defaults.headers.common["X-Custom-Header"] = "Angular.js";
  $http.get('build.version.json').success(function(data, status, headers, config) {
      $scope.data = data;
    });
});