function AdjustService() {
  function date(date) {
    var str = date.replace(/ \+/,'+').replace(' ','T');
    return str.slice(0,22) + ':' + str.slice(22);
  }

  this.date = date;
}

angular.module('app')
  .service('AdjustService', AdjustService);