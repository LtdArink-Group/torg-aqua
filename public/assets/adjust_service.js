function AdjustService() {
  function date(date) {
    return date.substring(0, 16).replace(' ', 'T');
  }

  this.date = date;
}

angular.module('app')
  .service('AdjustService', AdjustService);