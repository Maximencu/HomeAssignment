/**
 * @Author: Maximencu Mihai-Ion
 * @Description:This is the test class related to WeatherService.cls
 * @CreatedDate: 13/11/2024
 */
@IsTest
public class WeatherServiceTest {

    /**
     * * Inner class to test testGetWeatherPositive. 
     */
    private class WeatherServiceHttpMockPositive implements HttpCalloutMock {
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
     * verifies that the response matches the expected values. It tests scenarios with UTC+ / UTC-
     */
    @IsTest
    static void testGetWeatherPositive() {
        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, new WeatherServiceHttpMockPositive());

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

    /**
     * * Inner class to test testGetWeatherPositiveUTC. 
     */
    private class WeatherServiceHttpMockUTC implements HttpCalloutMock {
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
            res.setBody('{"city": {"name": "Test City", "timezone": 0}, "list": [' +
                        '{"dt_txt": "' + tomorrowString + ' 12:00:00", "main": {"temp": 290.15, "humidity": 70, "pressure": 1013}, "weather": [{"main": "Clear"}]}]}');
            return res;
        }
    }

    /**
     * This method tests the getWeather method from  WeatherService. This test sets up the HTTP callout mock, invokes getWeather, and
     * verifies that the response matches the expected values. It tests scenarios with UTC = 0
     */
    @IsTest
    static void testGetWeatherPositiveUTC() {
        // Set the mock response for the HTTP callout
        Test.setMock(HttpCalloutMock.class, new WeatherServiceHttpMockUTC());

        // Call the method with a sample location
        WeatherService.weatherObj result = WeatherService.getWeather('Test Location');

        // Assert that the response contains expected values
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals('Test City', result.name, 'City name should match the mocked response');
        System.assertEquals('UTC', result.timezone, 'Timezone should match the mocked response');
        System.assertEquals('Clear', result.weatherConditions, 'Weather conditions should match the mocked response');
        System.assertEquals('17.00', result.temp, 'Temperature in Celsius should match the converted value');
        System.assertEquals('70', result.humidity, 'Humidity should match the mocked response');
        System.assertEquals('1013', result.pressure, 'Pressure should match the mocked response');
    }

    /**
     * Mock class to simulate a failed HTTP response with a 404 status.
     */
    private class WeatherServiceHttpMockNegative implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Not Found"}');
            return res;
        }
    }
    /**
     * This method tests the getWeather method from  WeatherService. This tests the scenario when we receive a bad response from server (404)
     */
    @IsTest
    public static void testGetWeatherNegative() {
        Test.setMock(HttpCalloutMock.class, new WeatherServiceHttpMockNegative());

        Test.startTest();
        try {
            WeatherService.getWeather('Test City');
            System.assert(false, 'Expected AuraHandledException for failed data retrieval.');
        } catch (AuraHandledException e) {
            System.assertEquals(false,String.isblank(e.getMessage()));
        }
        Test.stopTest();
    }
}