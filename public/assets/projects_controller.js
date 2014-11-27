function ProjectsController($http, AdjustService) {
  var projects = this;
  projects.count = 0;
  projects.processedDate = projects.lastSyncTime = Date.parse('2000-01-01');
  projects.outdated = '';

  function outdated() {
    var diff = (Date.now() - projects.lastSyncTime) / (1000 * 3600 * 24);
    return (diff > 1) ? 'danger' : '';
  }

  $http.get('/projects.json')
    .success(function (data) {
      projects.count = data.count;
      projects.processedDate = Date.parse(data.processedDate);
      projects.lastSyncTime = Date.parse(AdjustService.date(data.lastSyncTime));
      projects.outdated = outdated();
    })
}

angular.module('app')
  .controller('ProjectsController', ProjectsController);

