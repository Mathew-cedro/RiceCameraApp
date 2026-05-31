# Pal-AI: Harvest Stage Detection System

**Developer:** Mathew R Cedro

This repository contains the core logic, user interface, and image processing backend for the Pal-AI mobile application.

## Repository Contents

### Flutter Application (Frontend)
* **Dart Files (`lib/`):** Contains the main application logic, cross-platform UI, and data models.
* **`pubspec.yaml`:** Defines all project dependencies and asset configurations.
* **`build.gradle`:** Contains the Android-specific build configurations.

### ⚙️ Python Backend (Image Processing)
* **`server.py`:** Handles the server connection and executes the core OpenCV logic used to classify the palay harvest stages.

## ⚠️Important Setup Instructions

For security purposes, the Supabase URL and API keys are **not included** in this repository. 

To run this code locally, you must create a `.env` file in your root directory to store your credentials. 

**Example `.env` format:**
```env
SUPABASE_URL=your_project_url_here
SUPABASE_KEY=your_anon_key_here
