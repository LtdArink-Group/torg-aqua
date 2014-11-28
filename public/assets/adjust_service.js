function AdjustService() {
  function date(date) {
    return date.replace(/ \+/,'+').replace(' ','T');
  }

  this.date = date;
}

angular.module('app')
  .service('AdjustService', AdjustService);