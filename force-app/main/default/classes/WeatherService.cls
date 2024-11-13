/**
 * @Author: Maximencu Mihai-Ion
 * @CreatedDate: 13/11/2024
 *  @Description: WeatherService is an Apex class that fetches weather forecast data for a given location.
 *  This class integrates with an external weather API to retrieve weather data, including
 *  temperature, humidity, pressure, and weather conditions for the specified location.
 */
public with sharing class WeatherService {

    /**
    * @Description: This method calls an external weather API to fetch forecast data for tomorrow.
     * The response data is parsed and mapped to a weatherObj instance, which includes
     * temperature, humidity, pressure, timezone, city name, and weather conditions.
    * @param location: The name of the city/location for which to fetch the weather forecast.This is a required parameter and is used to query the weather API.
     */
    @AuraEnabled(cacheable=true)
    public static weatherObj getWeather(String location) {
        // Use Metadata Operations to extract endpoint and key as Best Practice
        Public_API__mdt weatherMDT = Public_API__mdt.getInstance('Weather_Service');
        String endpoint = weatherMDT.Endpoint__c;
        String apiKey = weatherMDT.Key__c;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //Construct the API endpoint using endpoint along with city/location and key provided by external system. User EncodingUtil to ensure string is safe
        request.setEndpoint(endpoint + '?q=' + EncodingUtil.urlEncode(location, 'UTF-8') + '&appid=' + apiKey);
        request.setMethod('GET');
        
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            System.debug('responseData ->' + responseData);

            // Get today's date and calculate tomorrow's date in "YYYY-MM-DD" format to match with the one from payload
            Date today = Date.today();
            System.debug('TODAY ->>> ' + today);
            // Create a Datetime instance for today at 12:00 PM
            Datetime todayDT = Datetime.newInstance(today.year(), today.month(), today.day());
            System.debug('Today Date time (will display yesterday) ->>>> ' + todayDT);
            // Add 2 days to get tomorrow at 12:00 PM
            Datetime tomorrowDT = todayDT.addDays(2);
            System.debug('Tomorrow Date Time ->>>> ' + tomorrowDT);
            // Format the date portion for comparison with the forecast data
            String tomorrowString = tomorrowDT.formatGmt('yyyy-MM-dd');
            System.debug('Tomorrow String -> ' + tomorrowString);

            // Find the first forecast entry for tomorrow
            List<Object> forecastList = (List<Object>) responseData.get('list');
            Map<String, Object> tomorrowForecast;
            for (Object entry : forecastList) {
                Map<String, Object> forecastEntry = (Map<String, Object>) entry;
                String dtTxt = (String) forecastEntry.get('dt_txt');
                System.debug('forecastEntry  ->' + forecastEntry);
                
                // Check if dt_txt starts with tomorrow's date and save the date when it reaches 12:00 PM
                if (dtTxt != null && dtTxt.startsWith(tomorrowString + ' 12:00:00')) {
                    System.debug('Enter condition  ');
                    System.debug('FOUND forecastEntry  needed->  ' + forecastEntry);
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
            //Payload offer timezone as an offset (seconds) and will be formatted to UTC
            Integer timezoneOffsetSeconds = Integer.valueOf(((Map<String, Object>) responseData.get('city')).get('timezone'));
            Integer timezoneOffsetHours = timezoneOffsetSeconds / 3600;
            String timezoneFormatted = '';
            if(timezoneOffsetHours == 0){
                timezoneFormatted = 'UTC';
            } else {
                String sign = timezoneOffsetHours > 0 ? '+' : '';
                timezoneFormatted = 'UTC' + sign + timezoneOffsetHours;
 
            }
            weather.timezone = timezoneFormatted;

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

    // Define the weatherObj class as an inner class (Wrapper Class)
    public class weatherObj {
        @AuraEnabled public String name;
        @AuraEnabled public String temp; //This is saved in Celsius instead of Farenheit (as in payload)
        @AuraEnabled public String weatherConditions; //Weather description (Clouds, Rain, etc..)
        @AuraEnabled public String timezone; //This timezone has offset in seconds
        @AuraEnabled public String humidity;
        @AuraEnabled public String pressure;
    }
}