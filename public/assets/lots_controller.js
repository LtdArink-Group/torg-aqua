function LotsController($http) {
  var lots = this;
  lots.count = lots.pendingCount = 0;
  lots.consistent = 'good';
  lots.outdated = '';
  lots.pending = [1,2,3];

  function convert_times(data) {
    data = data.map(function(d){
      d['time'] = Date.parse(d['time']);
      return d;
    })
    return data;
  }

  function consistent() {
    return (lots.pendingCount != 0) ? 'danger' : 'good';
  }

  function outdated() {
    var diff = (Date.now() - lots.lastSyncTime) / (1000 * 660);
    return (diff > 1) ? 'danger' : '';
  }

  $http.get('http://172.30.40.100:9393/lots.json')
    .success(function (data) {
      lots.count = data.count;
      lots.pendingCount = data.pending.length;
      lots.lastSyncTime = Date.parse(data.lastSyncTime);
      lots.pending = convert_times(data.pending);
      lots.consistent = consistent();
      lots.outdated = outdated();
    })
}

angular.module('app')
  .controller('LotsController', LotsController);

