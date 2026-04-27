# Slide 1: Title Slide
**Title:** MyNest: A Digital Family Sanctuary
**Subtitle:** Preserving Memories, Connecting Generations
**Presenter:** Mursalin
**Course/Project:** Final Year Design Project
**Date:** [Insert Date]

# Slide 2: Problem Statement
**The Challenge:**
- Family histories and memories are often lost across generations.
- Physical photo albums degrade and are hard to share across vast distances.
- Existing social media platforms lack privacy and focus on temporary engagement rather than long-term legacy preservation.

# Slide 3: The Solution
**Introducing MyNest:**
- A private, secure digital vault for families to upload, share, and preserve photos, stories, and audio memories.
- Features an intelligent, auto-generating Family Tree.
- Prioritizes data privacy and curated family connections over public social networking.

# Slide 4: Key Features & Core Mechanics
- **Memory Studio:** Record inline audio notes, type detailed stories, and upload vintage photos directly to the vault.
- **Smart Family Tree:** As memories are added, the system parses contributor relationships and dynamically constructs a visual family tree.
- **Contribute Links:** Generate secure web links to allow elderly family members to contribute memories via a simple web portal without installing the app.
- **Master Profile Sync:** Users' profiles are instantly synchronized across all interactions (Vault, Tree, and Appwrite backend).

# Slide 5: System Architecture
- **Frontend Framework:** Flutter (Cross-platform support for iOS, Android, and Web).
- **Backend Infrastructure:** Appwrite (BaaS) providing serverless Authentication, Databases, and Storage.
- **AI Integration (Gemini 3.1 Flash):**
  - **Family Story Book:** Gemini reads raw collected stories and dynamically creates beautiful, cinematic narrative scripts based on those collected stories.
  - **Family Tree:** Gemini does *not* generate the graphical tree. It only determines familial relationships. Our app's internal logic then uses these relations to draw the visual tree.

# Slide 6: Database & Storage Strategy
**Appwrite Implementation:**
- **Collections:** `users`, `family_members`, `memories`, `links`.
- **Storage Buckets:** `mynest_files` (for memory artifacts) and `profile_photos`.
- **Security:** Strict permission schemas ensure memories are only accessible to designated family members.

# Slide 7: The "Contribute" Web Portal
- A lightweight, vanilla JavaScript and HTML web portal.
- Designed specifically for digital accessibility.
- Relatives can click a shared link, upload a photo, write a story, and submit it straight into the family's MyNest pending approval queue.

# Slide 8: Development Challenges & Solutions
- **Challenge:** Handling complex asynchronous state for the audio recorder and avoiding UI rendering clashes (Hero tag collisions).
- **Solution:** Re-architected the audio recorder to an inline widget using the `record` and `audioplayers` packages, and managed unique UI keys for seamless navigation.
- **Challenge:** Organizing the dynamic Family Tree data.
- **Solution:** Implemented a dual-fallback system (Gemini AI for complex relationships, with a robust keyword-based parsing fallback for instantaneous rendering).

# Slide 9: Future Scope & Phase 2
- End-to-end encryption for the Memory Vault.
- High-fidelity physical photobook generation and printing services.
- Multi-language localization to support diverse family backgrounds.
- Enhanced video memory support and automated transcription.

# Slide 10: Live Demonstration
- **Demo Flow:**
  1. Instant test account bypass (Simulating authenticated entry).
  2. The Memory Studio (Native Audio Recording & Upload).
  3. The Auto-Populating Family Tree.
  4. The MyNest Web Portal Contribution Workflow.

# Slide 11: Conclusion
**Summary:**
- MyNest bridges the generational gap, providing a modern, secure, and intuitive platform to guarantee that no family story is ever forgotten.
- **Thank You!**
- *Any Questions?*
