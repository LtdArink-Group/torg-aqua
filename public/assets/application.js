angular.module('app', ['angularCharts']);

function ChartController($scope) {
 $scope.config = {
    title: 'Лоты',
    tooltips: true,
    labels: false,
    mouseover: function() {},
    mouseout: function() {},
    click: function() {},
    legend: {
      display: false,
      //could be 'left, right'
      position: 'right'
    }
  };

  $scope.data = {
    series: ['Обработано', 'Ошибки'],
    data: [{
      x: "Январь 2014",
      y: [78, 15],
      tooltip: "this is tooltip"
    }, {
      x: "Февраль 2014",
      y: [64, 10]
    }, {
      x: "Март 2014",
      y: [351, 0]
    }, {
      x: "Апрель 2014",
      y: [54, 0]
    }]
  };
};

angular.module('app')
  .controller('ChartController',ChartController);
