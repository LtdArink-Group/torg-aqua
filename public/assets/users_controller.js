function UsersController($http) {
  var app = this;
  app.count = 0;
  $http.get('http://172.30.40.100:9393/users.json')
    .success(function (data) {
      app.count = data;
    })
}

angular.module('app')
  .controller('UsersController', UsersController);

