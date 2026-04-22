// ═══════════════════════════════════════════════
// MyNest Web — Premium Interactive App Logic
// Multi-image upload with per-image stories,
// Audio recording, and Appwrite integration
// ═══════════════════════════════════════════════

// ── Appwrite Init ──
const client = new Appwrite.Client();
client
    .setEndpoint('https://nyc.cloud.appwrite.io/v1')
    .setProject('687e9e6200375f703df2');

const databases = new Appwrite.Databases(client);
const storage = new Appwrite.Storage(client);
const DATABASE_ID = '69e916610024758bfa45';
const LINKS_COLLECTION = 'links';
const MEMORIES_COLLECTION = 'memories';
const BUCKET_ID = 'mynest_files';

// ── URL Parsing ──
const urlParams = new URLSearchParams(window.location.search);
let linkId = urlParams.get('link');

if (!linkId) {
    const pathSegments = window.location.pathname.split('/').filter(s => s.length > 0);
    const lastSegment = pathSegments.pop();
    if (lastSegment && !lastSegment.includes('.html') && lastSegment !== 'contribute' && lastSegment !== 'photo-story') {
        linkId = lastSegment;
    }
}

let currentLink = null;

// ═══════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════
async function init() {
    if (!linkId) {
        showError();
        return;
    }

    try {
        currentLink = await databases.getDocument(DATABASE_ID, LINKS_COLLECTION, linkId);

        // Photo context link
        if (currentLink.type === 'photo_context' && currentLink.photoUrl) {
            document.getElementById('photo-context-section').classList.remove('hidden');
            document.getElementById('shared-photo').src = currentLink.photoUrl;
            document.getElementById('author-question').textContent =
                currentLink.description || "Do you know the story behind this photo?";
        }

        // Show main content
        document.getElementById('loader').classList.add('hidden');
        document.getElementById('main-content').classList.remove('hidden');

    } catch (e) {
        console.error('Init error:', e);
        showError();
    }
}

function showError() {
    document.getElementById('loader').classList.add('hidden');
    document.getElementById('error-state').classList.remove('hidden');
}

// ═══════════════════════════════════════════════
// PHOTO UPLOAD — Multi-image with per-image story
// ═══════════════════════════════════════════════
const uploadedPhotos = []; // { file: File, previewUrl: string, story: string }

const dropzone = document.getElementById('uploadDropzone');
const photoInput = document.getElementById('photoInput');
const photoGrid = document.getElementById('photoGrid');

// Click to browse
dropzone.addEventListener('click', () => photoInput.click());

// Drag & drop
dropzone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropzone.classList.add('drag-over');
});

dropzone.addEventListener('dragleave', () => {
    dropzone.classList.remove('drag-over');
});

dropzone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropzone.classList.remove('drag-over');
    handleFiles(e.dataTransfer.files);
});

// File input change
photoInput.addEventListener('change', (e) => {
    handleFiles(e.target.files);
    photoInput.value = ''; // reset so same file can be re-selected
});

function handleFiles(fileList) {
    for (const file of fileList) {
        if (!file.type.startsWith('image/')) continue;
        const previewUrl = URL.createObjectURL(file);
        uploadedPhotos.push({ file, previewUrl, story: '' });
    }
    renderPhotoGrid();
}

function renderPhotoGrid() {
    if (uploadedPhotos.length === 0) {
        photoGrid.classList.add('hidden');
        dropzone.style.display = '';
        return;
    }

    dropzone.style.display = 'none';
    photoGrid.classList.remove('hidden');
    photoGrid.innerHTML = '';

    uploadedPhotos.forEach((photo, index) => {
        const card = document.createElement('div');
        card.className = 'photo-card';
        card.style.animationDelay = `${index * 0.1}s`;
        card.innerHTML = `
            <img src="${photo.previewUrl}" class="photo-card-img" alt="Photo ${index + 1}">
            <button type="button" class="photo-remove-btn" data-index="${index}">✕</button>
            <div class="photo-card-body">
                <textarea
                    placeholder="What's the story behind this photo?"
                    data-index="${index}"
                    class="photo-story-input"
                >${photo.story}</textarea>
            </div>
        `;
        photoGrid.appendChild(card);
    });

    // Add "Add more" card
    const addMore = document.createElement('div');
    addMore.className = 'add-more-photos';
    addMore.innerHTML = `
        <span class="add-more-icon">➕</span>
        <span class="add-more-text">Add More Photos</span>
    `;
    addMore.addEventListener('click', () => photoInput.click());
    photoGrid.appendChild(addMore);

    // Event delegation for remove buttons
    photoGrid.querySelectorAll('.photo-remove-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const idx = parseInt(btn.dataset.index);
            URL.revokeObjectURL(uploadedPhotos[idx].previewUrl);
            uploadedPhotos.splice(idx, 1);
            renderPhotoGrid();
        });
    });

    // Event delegation for story inputs
    photoGrid.querySelectorAll('.photo-story-input').forEach(textarea => {
        textarea.addEventListener('input', (e) => {
            const idx = parseInt(textarea.dataset.index);
            uploadedPhotos[idx].story = e.target.value;
        });
    });
}

// ═══════════════════════════════════════════════
// AUDIO RECORDING
// ═══════════════════════════════════════════════
let mediaRecorder;
let audioChunks = [];
let audioBlob = null;
let recordingInterval = null;
let recordingSeconds = 0;

const recordBtn = document.getElementById('recordBtn');
const recordText = document.getElementById('recordText');
const recordTimer = document.getElementById('recordTimer');
const audioPlaybackContainer = document.getElementById('audioPlaybackContainer');
const audioPlayback = document.getElementById('audioPlayback');
const deleteAudioBtn = document.getElementById('deleteAudioBtn');

recordBtn.addEventListener('click', async () => {
    if (mediaRecorder && mediaRecorder.state === 'recording') {
        // Stop recording
        mediaRecorder.stop();
        clearInterval(recordingInterval);
        recordBtn.classList.remove('recording');
        recordText.textContent = 'Record Your Voice';
        recordTimer.classList.add('hidden');
        return;
    }

    try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        mediaRecorder = new MediaRecorder(stream);
        audioChunks = [];
        recordingSeconds = 0;

        mediaRecorder.ondataavailable = (event) => {
            if (event.data.size > 0) audioChunks.push(event.data);
        };

        mediaRecorder.onstop = () => {
            audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
            audioPlayback.src = URL.createObjectURL(audioBlob);
            audioPlaybackContainer.classList.remove('hidden');
            recordBtn.style.display = 'none';
            // Stop all tracks
            stream.getTracks().forEach(t => t.stop());
        };

        mediaRecorder.start();
        recordBtn.classList.add('recording');
        recordText.textContent = 'Stop Recording';
        recordTimer.classList.remove('hidden');

        // Timer
        recordingInterval = setInterval(() => {
            recordingSeconds++;
            const mins = Math.floor(recordingSeconds / 60);
            const secs = recordingSeconds % 60;
            recordTimer.textContent = `${mins}:${secs.toString().padStart(2, '0')}`;
        }, 1000);

    } catch (err) {
        console.error("Microphone access denied", err);
        alert("Please allow microphone access to record audio.");
    }
});

deleteAudioBtn.addEventListener('click', () => {
    audioBlob = null;
    audioPlayback.src = '';
    audioPlaybackContainer.classList.add('hidden');
    recordBtn.style.display = 'flex';
});

// ═══════════════════════════════════════════════
// FORM SUBMISSION
// ═══════════════════════════════════════════════
document.getElementById('memory-form').addEventListener('submit', async (e) => {
    e.preventDefault();

    const storyText = document.getElementById('story').value.trim();
    const hasPhotosWithStories = uploadedPhotos.some(p => p.story.trim().length > 0);

    if (!storyText && !audioBlob && !hasPhotosWithStories) {
        alert("Please write a story, record audio, or add a photo with a description!");
        return;
    }

    const submitBtn = document.getElementById('submit-btn');
    const btnText = submitBtn.querySelector('.btn-text');
    submitBtn.disabled = true;
    btnText.textContent = 'Preparing…';

    const name = document.getElementById('contributorName').value.trim();
    const relation = document.getElementById('contributorRelation').value.trim();
    const title = document.getElementById('title').value.trim();

    try {
        // 1. Upload audio if exists
        let finalAudioUrl = null;
        if (audioBlob) {
            btnText.textContent = 'Uploading audio…';
            const file = new File([audioBlob], `audio_${Date.now()}.webm`, { type: 'audio/webm' });
            const uploaded = await storage.createFile(BUCKET_ID, Appwrite.ID.unique(), file);
            finalAudioUrl = `https://nyc.cloud.appwrite.io/v1/storage/buckets/${BUCKET_ID}/files/${uploaded.$id}/view?project=687e9e6200375f703df2`;
        }

        // 2. Upload photos and create one memory per photo
        if (uploadedPhotos.length > 0) {
            for (let i = 0; i < uploadedPhotos.length; i++) {
                const photo = uploadedPhotos[i];
                btnText.textContent = `Uploading photo ${i + 1} of ${uploadedPhotos.length}…`;

                const uploaded = await storage.createFile(BUCKET_ID, Appwrite.ID.unique(), photo.file);
                const photoUrl = `https://nyc.cloud.appwrite.io/v1/storage/buckets/${BUCKET_ID}/files/${uploaded.$id}/view?project=687e9e6200375f703df2`;

                // Each photo gets its own memory document
                const photoStory = photo.story.trim() || storyText || "Photo Memory";
                const photoTitle = uploadedPhotos.length > 1
                    ? `${title} (${i + 1}/${uploadedPhotos.length})`
                    : title;

                await databases.createDocument(
                    DATABASE_ID,
                    MEMORIES_COLLECTION,
                    Appwrite.ID.unique(),
                    {
                        userId: currentLink.userId,
                        title: photoTitle,
                        story: photoStory,
                        contributorName: name,
                        contributorRelation: relation,
                        photoUrl: photoUrl,
                        audioUrl: i === 0 ? finalAudioUrl : null, // attach audio to first photo only
                        isApproved: false,
                        status: 'raw',
                        visibility: 'public'
                    }
                );
            }
        } else {
            // 3. No photos — just text/audio memory
            btnText.textContent = 'Saving memory…';

            await databases.createDocument(
                DATABASE_ID,
                MEMORIES_COLLECTION,
                Appwrite.ID.unique(),
                {
                    userId: currentLink.userId,
                    title: title,
                    story: storyText || "Audio Memory",
                    contributorName: name,
                    contributorRelation: relation,
                    photoUrl: currentLink.type === 'photo_context' ? currentLink.photoUrl : null,
                    audioUrl: finalAudioUrl,
                    isApproved: false,
                    status: 'raw',
                    visibility: 'public'
                }
            );
        }

        // Success!
        document.getElementById('form-card').classList.add('hidden');
        document.getElementById('success-state').classList.remove('hidden');
        window.scrollTo({ top: 0, behavior: 'smooth' });

    } catch (err) {
        console.error('Submit error:', err);
        alert('Error submitting memory. Please try again.');
        submitBtn.disabled = false;
        btnText.textContent = 'Submit to Family Vault';
    }
});

// ═══════════════════════════════════════════════
// LAUNCH
// ═══════════════════════════════════════════════
init();
