# MyNest - A Digital Family Sanctuary

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
<img width="935" height="1575" alt="image" src="https://github.com/user-attachments/assets/ad6998d5-676a-4cd4-b2c3-611f204de4f8" />

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

<img width="373" height="783" alt="image" src="https://github.com/user-attachments/assets/9791df2e-ce63-42bb-9853-30086545d6c7" />  |  <img width="373" height="783" alt="image" src="https://github.com/user-attachments/assets/f58b0395-9d85-4236-8c51-8c649933fda2" />
<img width="373" height="783" alt="image" src="https://github.com/user-attachments/assets/8572e138-4dbb-4679-8ca8-c5f68d7053b7" />  |  <img width="373" height="783" alt="image" src="https://github.com/user-attachments/assets/d648a21d-978e-47f5-95b5-d00fb614190e" />
<img width="373" height="783" alt="image" src="https://github.com/user-attachments/assets/0c4916cd-3665-4864-8f62-349df2e2ad81" />  |  <img width="379" height="795" alt="image" src="https://github.com/user-attachments/assets/ed8a9762-ff23-4d1b-a233-8a8c4d2be19a" />
<img width="352" height="736" alt="image" src="https://github.com/user-attachments/assets/65f837f0-b754-40ca-b3f8-55fe12e52d48" />  |  <img width="366" height="767" alt="image" src="https://github.com/user-attachments/assets/cde3769f-b9ee-43f4-9f32-87b5dd14f330" />
<img width="466" height="468" alt="image" src="https://github.com/user-attachments/assets/abc4fd9c-ca71-4713-a477-e39a64d4f8d7" />  |  <img width="520" height="474" alt="image" src="https://github.com/user-attachments/assets/482352df-38ae-4ad6-bd1d-3b314699c3f2" />







## 6. Conclusion and Future Work
MyNest successfully demonstrates a cohesive integration of mobile development, serverless backend architecture, and AI-driven data organization. The project meets all core objectives, providing a robust platform for digital legacy preservation. 
Future iterations will focus on implementing end-to-end encryption for the storage buckets and adding high-fidelity automated photobook printing capabilities.
