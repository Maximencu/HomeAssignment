import { LightningElement, api, track, wire } from 'lwc';
import getWeather from '@salesforce/apex/WeatherService.getWeather';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import LOCATION_FIELD from '@salesforce/schema/Account.Location__c';

export default class WeatherDisplay extends LightningElement {
    @api recordId;

    @track temperature;
    @track weatherConditions;
    @track name;
    @track timezone;
    @track humidity;
    @track pressure;

    @track error;
    previousLocation;

    @wire(getRecord, { recordId: '$recordId', fields: [LOCATION_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            const location = getFieldValue(data, LOCATION_FIELD);
            if (location && location !== this.previousLocation) {
                this.previousLocation = location;
                this.fetchWeather(location);
            }
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
        }
    }

    fetchWeather(location) {
        getWeather({ location })
            .then((result) => {
                this.temperature = result.temp;
                this.weatherConditions = result.weatherConditions;
                this.name = result.name;
                this.timezone = result.timezone;
                this.humidity = result.humidity;
                this.pressure = result.pressure;
                this.error = undefined;
            })
            .catch((error) => {
                this.temperature = undefined;
                this.weatherConditions = undefined;
                this.name = undefined;
                this.timezone = undefined;
                this.humidity =undefined;
                this.pressure = undefined;
                this.error = error.body ? error.body.message : error.message;
            });
    }
}