d3.json('/stats.json', function(data) {
  for(var i=0;i<data.length;i++) {
    data[i] = convert_dates(data[i], 'date');
  }
  data_graphic({
    data: data,
    width: 1160,
    height: 300,
    target: '#history-chart',
    x_accessor: 'date',
    y_accessor: 'value',
    custom_line_color_map: [2, 3]
  })
})
