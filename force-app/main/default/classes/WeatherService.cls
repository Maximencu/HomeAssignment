public with sharing class WeatherService {

    @AuraEnabled(cacheable=true)
    public static weatherObj getWeather(String location) {
        // Retrieve the custom metadata instance
        Public_API__mdt weatherMDT = Public_API__mdt.getInstance('Weather_Service');
        String endpoint = weatherMDT.Endpoint__c;
        String apiKey = weatherMDT.Key__c;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint + '?q=' + EncodingUtil.urlEncode(location, 'UTF-8') + '&appid=' + apiKey);
        request.setMethod('GET');
        
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('responseData ->' + responseData);

            // Get today's date and calculate tomorrow's date in "YYYY-MM-DD" format to match with the one from payload
            Date tomorrow = Date.today().addDays(1);
            Datetime tomorrowDatetime = Datetime.newInstance(tomorrow.year(), tomorrow.month(), tomorrow.day());
            String tomorrowString = tomorrowDatetime.formatGmt('yyyy-MM-dd');
            System.debug('tomorrowString  -> ' + tomorrowString);

            // Find the first forecast entry for tomorrow
            List<Object> forecastList = (List<Object>) responseData.get('list');
            Map<String, Object> tomorrowForecast;
            for (Object entry : forecastList) {
                Map<String, Object> forecastEntry = (Map<String, Object>) entry;
                String dtTxt = (String) forecastEntry.get('dt_txt');
                System.debug('forecastEntry  ->' + forecastEntry);
                
                // Check if dt_txt starts with tomorrow's date
                if (dtTxt != null && dtTxt.startsWith(tomorrowString)) {
                    System.debug('Enter condition  ');
                    System.debug('forecastEntry  ->  ' + forecastEntry);
                    System.debug('dtTXT ->' + dtTxt);
                    tomorrowForecast = forecastEntry;
                    break;
                }
            }

            if (tomorrowForecast == null) {
                throw new AuraHandledException('Tomorrow\'s forecast not available');
            }

            // Create an instance of weatherObj and populate it with values from tomorrowForecast directly
            System.debug('Tomorrow Forecast ->'  + tomorrowForecast);
            weatherObj weather = new weatherObj();
            weather.name = (String) ((Map<String, Object>) responseData.get('city')).get('name');
            weather.timezone = String.valueOf(((Map<String, Object>) responseData.get('city')).get('timezone'));

            // Extract values directly from the "main" section of tomorrowForecast
            weather.humidity = String.valueOf(((Map<String, Object>) tomorrowForecast.get('main')).get('humidity'));
            weather.pressure = String.valueOf(((Map<String, Object>) tomorrowForecast.get('main')).get('pressure'));

            // Convert temperature from Kelvin to Celsius and format it
            Decimal temperatureKelvin = (Decimal) ((Map<String, Object>) tomorrowForecast.get('main')).get('temp');
            Decimal temperatureCelsius = temperatureKelvin - 273.15;
            weather.temp = String.valueOf(temperatureCelsius.setScale(2));

            // Extract weather conditions from the first element in "weather" array
            List<Object> weatherArray = (List<Object>) tomorrowForecast.get('weather');
            if (weatherArray != null && !weatherArray.isEmpty()) {
                Map<String, Object> weatherDetails = (Map<String, Object>) weatherArray[0];
                weather.weatherConditions = (String) weatherDetails.get('main');
            }

            return weather;
        } else {
            throw new AuraHandledException('Failed to retrieve weather data');
        }
    }

    // Define the weatherObj class as an inner class
    public class weatherObj {
        @AuraEnabled public String name;
        @AuraEnabled public String temp;
        @AuraEnabled public String weatherConditions;
        @AuraEnabled public String timezone;
        @AuraEnabled public String humidity;
        @AuraEnabled public String pressure;
    }
}
