# Project Report: MyNest - A Digital Family Sanctuary

## 1. Introduction
Family histories, ancestral photos, and oral traditions are frequently lost across generations. Traditional physical albums degrade over time, and modern social media platforms are optimized for transient sharing rather than long-term, private legacy preservation. MyNest is a cross-platform application designed to solve this by providing families with a secure, intelligent, and interactive digital vault.

## 2. Objectives
- **Secure Preservation:** Create a digital vault for photos, stories, and audio recordings.
- **Intelligent Organization:** Automatically construct a visual family tree based on user contributions and metadata.
- **Accessibility:** Ensure elderly family members can contribute via a simple, accessible web portal without needing to download a mobile app.
- **Privacy:** Implement a strict authentication and permission model to ensure family data remains private.

## 3. System Architecture & Technologies Used
The MyNest ecosystem consists of a mobile application, a web portal, and a serverless backend infrastructure.
- **Frontend (Mobile):** Built with the Flutter framework, utilizing Dart. Flutter was chosen for its high-performance rendering engine and ability to deploy to both iOS and Android from a single codebase.
- **Frontend (Web Portal):** A lightweight Vanilla JavaScript, HTML, and CSS portal designed for maximum compatibility and ease of use.
- **Backend (BaaS):** Appwrite serves as the core backend, providing:
  - Secure User Authentication (Email/Password & OTP).
  - NoSQL Databases for storing `memories`, `family_members`, and shareable `links`.
  - Storage Buckets for managing high-resolution photos and native audio recordings.
- **Artificial Intelligence:** Google Gemini 3.1 Flash API is integrated into the Appwrite Serverless Functions to intelligently parse family relationships and organize the dynamic family tree.

## 4. Core Features Implementation
### 4.1. The Memory Studio & Family Story Book
The Memory Studio is the primary interface for content creation, allowing users to upload archival photos, write detailed stories, and record native audio notes. Furthermore, Gemini AI is deeply integrated into the Family Story Book feature. When a user opens a collected memory in the Story Book, Gemini reads the raw collected story and dynamically creates a beautiful, cinematic, and emotional narrative script based on that specific collected story, bringing the family history to life.

### 4.2. Auto-Generating Family Tree
As memories are submitted and approved, the system scans the tagged contributors. The backend Appwrite Function leverages Gemini AI to evaluate relationship keywords (e.g., "Grandfather", "Aunt"). It is important to note that Gemini does not generate the full graphical family tree. Instead, Gemini's role is strictly to determine the exact relationships between members and organize them into hierarchical layers. Our mobile app's internal logic then takes this structured relation data and draws the visual family tree accordingly.

### 4.3. Contribute Link Portal
To bridge the digital divide for older generations, users can generate secure "Contribute Links" from the mobile app. These links direct to the MyNest Web Portal. The portal validates the link ID against the Appwrite database, allowing external relatives to upload artifacts directly into the mobile user's "pending approval" queue.

### 4.4. Security & Authentication Bypass for Demonstrations
The system features a custom 2FA OTP flow for standard users. However, to facilitate live demonstrations without network dependency for email delivery, a localized hardware bypass was engineered into the `AuthService`, creating a mocked session state specifically for the `test@gmail.com` profile.

## 5. Challenges and Solutions
1. **Challenge:** Synchronizing state between the web portal uploads and the mobile app's local state.
   **Solution:** Implemented continuous background synchronization mechanisms during the initialization (`_load()`) of core screens, ensuring data integrity without requiring manual refreshes.
2. **Challenge:** Handling native permissions for audio recording on Android while preventing UI thread blocking.
   **Solution:** Abstracted the recording logic into an asynchronous service utilizing `getApplicationDocumentsDirectory` for safe localized file writing before executing the Appwrite upload stream.

## 6. Conclusion and Future Work
MyNest successfully demonstrates a cohesive integration of mobile development, serverless backend architecture, and AI-driven data organization. The project meets all core objectives, providing a robust platform for digital legacy preservation. 
Future iterations will focus on implementing end-to-end encryption for the storage buckets and adding high-fidelity automated photobook printing capabilities.
