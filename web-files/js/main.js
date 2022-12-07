
/*
 * Connect to weather API
*Using custom key
 */

function weatherBalloon( cityID ) {
  var key = config.SECRET_API_KEY; //this calls the API key variable saved  within config.js
  var CityID = '2643741';
  fetch('https://api.openweathermap.org/data/2.5/weather?id=' + CityID + '&appid=' + key)  
  .then(function(resp) { return resp.json() }) // Convert data to json
  .then(function(data) {
    drawWeather(data); // Call drawWeather
  })
  .catch(function() {
    // catch any errors
  });
}



window.onload = function() {
  weatherBalloon( 2643741 );
}

function drawWeather( d ) {
	var celcius = Math.round(parseFloat(d.main.temp)-273.15);
	var fahrenheit = Math.round(((parseFloat(d.main.temp)-273.15)*1.8)+32); 
	var description = d.weather[0].description;
	
	document.getElementById('description').innerHTML = description;
	document.getElementById('temp').innerHTML = celcius + '&deg;';
	document.getElementById('location').innerHTML = d.name;
	
	if( description.indexOf('rain') > 0 ) {
  	document.body.className = 'rainy';
  } else if( description.indexOf('cloud') > 0 ) {
  	document.body.className = 'cloudy';
  } else if( description.indexOf('sunny') > 0 ) {
  	document.body.className = 'sunny';
  }
}