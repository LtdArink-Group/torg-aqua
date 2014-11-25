function LotsController($http) {
  var lots = this;
  lots.count = 100500;
  lots.pending = 200;
  // $http.get('http://172.30.40.100:9393/lots.json')
  //   .success(function (data) {
  //     lots.count = data;
  //   })
}

angular.module('app')
  .controller('LotsController', LotsController);

