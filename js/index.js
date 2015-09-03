var dataset, p3;

p3 = d3.select('body').selectAll('p');

dataset = [12, 24, 32];

p3.data(dataset).text(function(d, i) {
  return (i + 1) + "番目は" + d;
});
