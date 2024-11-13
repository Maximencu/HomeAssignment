/**
 * @Author: Maximencu Mihai-Ion
 * @Description:This is the test class related to WeatherService.cls
 * @CreatedDate: 13/11/2024
 */
@IsTest
public class WeatherServiceTest {

    /**
     * * Inner class implementing the HttpCalloutMock interface to simulate a callout response from the weather API. 
     */
    private class WeatherServiceHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Generate tomorrow's date in "yyyy-MM-dd" format using Datetime
            Date today = Date.today();
            // Create a Datetime instance for today at 12:00 PM
            Datetime todayDT = Datetime.newInstance(today.year(), today.month(), today.day());
            // Add 2 days to get tomorrow at 12:00 PM
            Datetime tomorrowDT = todayDT.addDays(2);
            // Format the date portion for comparison with the forecast data
            String tomorrowString = tomorrowDT.formatGmt('yyyy-MM-dd');

            // Mock response with the correct date format
            res.setBody('{"city": {"name": "Test City", "timezone": 7200}, "list": [' +
                        '{"dt_txt": "' + tomorrowString + ' 12:00:00", "main": {"temp": 290.15, "humidity": 70, "pressure": 1013}, "weather": [{"main": "Clear"}]}]}');
            return res;
        }
    }

    /**
     * Test method is  test the getWeather method from  WeatherService. This test sets up the HTTP callout mock, invokes getWeather, and
     * verifies that the response matches the expected values.
     */
    @IsTest
    static void testGetWeather() {
        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, new WeatherServiceHttpMock());

        // Call the method with a sample location
        WeatherService.weatherObj result = WeatherService.getWeather('Test Location');

        // Assert that the response contains expected values
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals('Test City', result.name, 'City name should match the mocked response');
        System.assertEquals('UTC+2', result.timezone, 'Timezone should match the mocked response');
        System.assertEquals('Clear', result.weatherConditions, 'Weather conditions should match the mocked response');
        System.assertEquals('17.00', result.temp, 'Temperature in Celsius should match the converted value');
        System.assertEquals('70', result.humidity, 'Humidity should match the mocked response');
        System.assertEquals('1013', result.pressure, 'Pressure should match the mocked response');
    }
}
