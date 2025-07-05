# MapTiler API Setup Guide

## Overview
This project uses MapTiler's geocoding API for location autocomplete functionality. The autocomplete feature allows users to search for locations as they type, with session management to optimize API usage.

## Setup Instructions

### 1. Get a MapTiler API Key
1. Go to [MapTiler Cloud](https://cloud.maptiler.com/)
2. Sign up for a free account or log in if you already have one
3. Navigate to your account dashboard
4. Create a new API key or use an existing one
5. Make sure the key has access to the **Geocoding API**

### 2. Configure the API Key
1. Open the file `lib/api/maptiler_autocomplete.dart`
2. Find the line:
   ```dart
   static const String _apiKey = 'YOUR_MAPTILER_API_KEY_HERE';
   ```
3. Replace `'YOUR_MAPTILER_API_KEY_HERE'` with your actual MapTiler API key
4. Save the file

### 3. API Usage Limits
- **Free Tier**: 100,000 requests per month
- **Paid Plans**: Higher limits available
- **Session Management**: The implementation uses session tokens to optimize API usage

## Features

### Autocomplete Functionality
- **Debounced Search**: Waits 300ms after user stops typing before making API calls
- **Session Management**: Uses session tokens to reduce API costs
- **Error Handling**: Graceful error handling with user-friendly messages
- **Location Selection**: Automatically updates map coordinates when a location is selected

### Session Management
- Sessions last for 1 hour
- Session tokens are automatically generated and managed
- Reduces API costs by grouping related requests

## Implementation Details

### Files Modified
1. `lib/api/maptiler_autocomplete.dart` - Core autocomplete service
2. `lib/widgets/location_autocomplete_field.dart` - UI component
3. `lib/widgets/list_room_form.dart` - Integration in room listing form

### Key Components
- `MapTilerAutocompleteService`: Handles API calls and session management
- `AutocompleteResult`: Data model for location results
- `LocationAutocompleteField`: Reusable UI component

## Testing
1. Run the app
2. Navigate to "List Your Room"
3. Go to the "Location & Availability" step
4. Start typing in the location field
5. Verify that autocomplete suggestions appear
6. Select a location and verify it populates the field

## Troubleshooting

### Common Issues
1. **No suggestions appearing**: Check your API key and internet connection
2. **API errors**: Verify your MapTiler account has sufficient credits
3. **Slow response**: Check your internet connection and API key permissions

### Debug Mode
To enable debug logging, you can add print statements in the `searchPlaces` method to see API responses.

## Security Notes
- Never commit your API key to version control
- Consider using environment variables for production
- Monitor your API usage to avoid unexpected charges

## Support
For MapTiler API issues, refer to the [MapTiler Documentation](https://docs.maptiler.com/api/geocoding/). 