# ParkingFinder

ParkingFinder is a mobile application that helps users find available parking spots around their location. The app retrieves the user's location, sends it to a backend server, fetches available parking spots, and displays them on a map.

## Features

- Retrieve and display the user's current location.
- Fetch and display available parking spots on a map.
- Show details of a selected parking spot.
- Get directions to a parking spot.
- Search for locations and display parking spots around them.
- Share parking spot location.
- Close directions and unselect parking spots.

## Technologies Used

- Swift
- UIKit
- CoreLocation
- MapKit
- URLSession
- Node.js (Backend)
- Express (Backend)

## Installation

### Prerequisites

- Xcode
- Node.js
- npm

### Backend Setup

1. Clone the backend repository and navigate to the project directory:
   ```
   git clone <backend-repo-url>
   cd backend-repo
   ```
2. Install the dependencies:
  ```
  npm install
  ```
3. Start the backend server:
  ```
  node server.js
  ```

### iOS App Setup

1. Clone the repository and navigate to the project directory:
  ```
  git clone https://github.com/RishabhChangwani/ParkingFinder.git
  cd ParkingFinder
  ```
2. Open the ParkingFinder.xcodeproj in Xcode:
  ```
  open ParkingFinder.xcodeproj
  ```
3. Build and run the app on a simulator or a physical device.

