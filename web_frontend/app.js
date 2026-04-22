// Initialize Appwrite
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

// Get the link ID from the URL query (?link=12345) or path (/contribute/12345)
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

async function init() {
    if (!linkId) {
        showError();
        return;
    }

    try {
        // Fetch link details
        currentLink = await databases.getDocument(DATABASE_ID, LINKS_COLLECTION, linkId);
        
        // If it's a photo context link, show the photo
        if (currentLink.type === 'photo_context' && currentLink.photoUrl) {
            document.getElementById('photo-context-section').classList.remove('hidden');
            document.getElementById('shared-photo').src = currentLink.photoUrl;
            
            if (currentLink.description) {
                document.getElementById('author-question').textContent = currentLink.description;
            } else {
                document.getElementById('author-question').textContent = "Do you know the story behind this photo?";
            }
        }

        // Show main content
        document.getElementById('loader').classList.add('hidden');
        document.getElementById('main-content').classList.remove('hidden');

    } catch (e) {
        console.error(e);
        showError();
    }
}

function showError() {
    document.getElementById('loader').classList.add('hidden');
    document.getElementById('error-state').classList.remove('hidden');
}

// Audio Recording Logic
let mediaRecorder;
let audioChunks = [];
let audioBlob = null;

const recordBtn = document.getElementById('recordBtn');
const recordText = document.getElementById('recordText');
const audioPlaybackContainer = document.getElementById('audioPlaybackContainer');
const audioPlayback = document.getElementById('audioPlayback');
const deleteAudioBtn = document.getElementById('deleteAudioBtn');

recordBtn.addEventListener('click', async () => {
    if (mediaRecorder && mediaRecorder.state === 'recording') {
        mediaRecorder.stop();
        recordBtn.classList.remove('recording');
        recordText.textContent = 'Start Recording';
        return;
    }

    try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        mediaRecorder = new MediaRecorder(stream);
        audioChunks = [];

        mediaRecorder.ondataavailable = (event) => {
            if (event.data.size > 0) audioChunks.push(event.data);
        };

        mediaRecorder.onstop = () => {
            audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
            const audioUrl = URL.createObjectURL(audioBlob);
            audioPlayback.src = audioUrl;
            audioPlaybackContainer.classList.remove('hidden');
            recordBtn.style.display = 'none';
        };

        mediaRecorder.start();
        recordBtn.classList.add('recording');
        recordText.textContent = 'Stop Recording';
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

// Handle Form Submission
document.getElementById('memory-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const story = document.getElementById('story').value.trim();
    if (!story && !audioBlob) {
        alert("Please either write a story or record audio!");
        return;
    }

    const submitBtn = document.getElementById('submit-btn');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Submitting...';

    const name = document.getElementById('contributorName').value.trim();
    const relation = document.getElementById('contributorRelation').value.trim();
    const title = document.getElementById('title').value.trim();

    try {
        let finalAudioUrl = null;

        // Upload audio if exists
        if (audioBlob) {
            submitBtn.textContent = 'Uploading Audio...';
            const file = new File([audioBlob], `audio_${Date.now()}.webm`, { type: 'audio/webm' });
            const uploadedFile = await storage.createFile(BUCKET_ID, Appwrite.ID.unique(), file);
            finalAudioUrl = `https://cloud.appwrite.io/v1/storage/buckets/${BUCKET_ID}/files/${uploadedFile.$id}/view?project=687e9e6200375f703df2`;
        }

        submitBtn.textContent = 'Saving Memory...';

        await databases.createDocument(
            DATABASE_ID,
            MEMORIES_COLLECTION,
            Appwrite.ID.unique(),
            {
                userId: currentLink.userId, // Send to the person who shared the link
                title: title,
                story: story || "Audio Memory",
                contributorName: name,
                contributorRelation: relation,
                photoUrl: currentLink.type === 'photo_context' ? currentLink.photoUrl : null,
                audioUrl: finalAudioUrl,
                isApproved: false, // Goes to Pending tab!
                status: 'raw',
                visibility: 'public'
            }
        );

        // Success
        document.getElementById('memory-form').classList.add('hidden');
        document.getElementById('success-msg').classList.remove('hidden');

    } catch (e) {
        console.error(e);
        alert('Error submitting memory. Please try again.');
        submitBtn.disabled = false;
        submitBtn.textContent = 'Submit to Family Vault';
    }
});

init();
