// ═══════════════════════════════════════════════
// MyNest Web — Full-Featured Memory Portal
// Profile photo, email verification, per-photo
// voice notes, multi-image upload
// ═══════════════════════════════════════════════

// ── Appwrite Init ──
const client = new Appwrite.Client();
client
    .setEndpoint('https://nyc.cloud.appwrite.io/v1')
    .setProject('687e9e6200375f703df2');

const databases = new Appwrite.Databases(client);
const storage = new Appwrite.Storage(client);
const account = new Appwrite.Account(client);
const DATABASE_ID = '69e916610024758bfa45';
const LINKS_COLLECTION = 'links';
const MEMORIES_COLLECTION = 'memories';
const BUCKET_ID = 'mynest_files';

// ── URL Parsing ──
const urlParams = new URLSearchParams(window.location.search);
let linkId = urlParams.get('link');
if (!linkId) {
    const segs = window.location.pathname.split('/').filter(s => s.length > 0);
    const last = segs.pop();
    if (last && !last.includes('.html') && last !== 'contribute' && last !== 'photo-story') {
        linkId = last;
    }
}

let currentLink = null;
let isEmailVerified = false;
let verificationUserId = null;
let profilePhotoFile = null;

// ═══════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════
async function init() {
    if (!linkId) { showError(); return; }
    try {
        currentLink = await databases.getDocument(DATABASE_ID, LINKS_COLLECTION, linkId);

        if (currentLink.type === 'photo_context' && currentLink.photoUrl) {
            document.getElementById('photo-context-section').classList.remove('hidden');
            document.getElementById('shared-photo').src = currentLink.photoUrl;
            document.getElementById('author-question').textContent =
                currentLink.description || "Do you know the story behind this photo?";
        }

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
// PROFILE PHOTO UPLOAD
// ═══════════════════════════════════════════════
const profileAvatar = document.getElementById('profileAvatar');
const profilePhotoInput = document.getElementById('profilePhotoInput');
const profilePreview = document.getElementById('profilePreview');
const avatarPlaceholder = document.querySelector('.avatar-placeholder');

profileAvatar.addEventListener('click', () => profilePhotoInput.click());

profilePhotoInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file || !file.type.startsWith('image/')) return;
    profilePhotoFile = file;
    const url = URL.createObjectURL(file);
    profilePreview.src = url;
    profilePreview.classList.remove('hidden');
    avatarPlaceholder.classList.add('hidden');
});

// ═══════════════════════════════════════════════
// EMAIL VERIFICATION (using Appwrite Email Tokens)
// ═══════════════════════════════════════════════
const emailInput = document.getElementById('contributorEmail');
const verificationSection = document.getElementById('verificationSection');
const verifyEmailDisplay = document.getElementById('verifyEmailDisplay');
const verifyOtpBtn = document.getElementById('verifyOtpBtn');
const resendOtpBtn = document.getElementById('resendOtpBtn');
const verifyError = document.getElementById('verifyError');
const verifiedBadge = document.getElementById('verifiedBadge');
const submitBtn = document.getElementById('submit-btn');
const otpDigits = document.querySelectorAll('.otp-digit');

// Auto-focus next OTP digit
otpDigits.forEach((input, idx) => {
    input.addEventListener('input', (e) => {
        const val = e.target.value.replace(/\D/g, '');
        e.target.value = val;
        if (val && idx < 5) otpDigits[idx + 1].focus();
    });
    input.addEventListener('keydown', (e) => {
        if (e.key === 'Backspace' && !e.target.value && idx > 0) {
            otpDigits[idx - 1].focus();
        }
    });
    // Allow paste of full code
    input.addEventListener('paste', (e) => {
        e.preventDefault();
        const pasted = (e.clipboardData.getData('text') || '').replace(/\D/g, '').slice(0, 6);
        pasted.split('').forEach((ch, i) => {
            if (otpDigits[i]) otpDigits[i].value = ch;
        });
        if (pasted.length === 6) otpDigits[5].focus();
    });
});

const sendOtpBtn = document.getElementById('sendOtpBtn');
const sendOtpError = document.getElementById('sendOtpError');
const sendOtpHint = document.getElementById('sendOtpHint');

// Send OTP on button click
let otpSentForEmail = '';
sendOtpBtn.addEventListener('click', async () => {
    const email = emailInput.value.trim();
    if (!email || !email.includes('@')) {
        sendOtpError.textContent = 'Please enter a valid email address first.';
        sendOtpError.classList.remove('hidden');
        return;
    }
    if (isEmailVerified) return;
    
    sendOtpBtn.disabled = true;
    sendOtpBtn.textContent = 'Sending...';
    sendOtpError.classList.add('hidden');
    
    await sendOtp(email);
});

async function sendOtp(email) {
    try {
        // Delete any existing anonymous session
        try { await account.deleteSession('current'); } catch (_) {}

        const token = await account.createEmailToken(Appwrite.ID.unique(), email);
        verificationUserId = token.userId;
        otpSentForEmail = email;

        verifyEmailDisplay.textContent = email;
        verificationSection.classList.remove('hidden');
        verifyError.classList.add('hidden');
        
        sendOtpBtn.textContent = 'Code Sent';
        sendOtpHint.textContent = 'Please check your email and enter the code below.';
        sendOtpHint.style.color = 'var(--sage)';
        
        otpDigits.forEach(d => d.value = '');
        otpDigits[0].focus();
    } catch (e) {
        console.error('OTP send error:', e);
        sendOtpError.textContent = 'Failed to send code. Please try again.';
        sendOtpError.classList.remove('hidden');
        sendOtpBtn.disabled = false;
        sendOtpBtn.textContent = 'Send Code';
    }
}

resendOtpBtn.addEventListener('click', async () => {
    const email = emailInput.value.trim();
    if (email) {
        resendOtpBtn.textContent = 'Sending…';
        await sendOtp(email);
        resendOtpBtn.textContent = 'Code Resent!';
        setTimeout(() => { resendOtpBtn.textContent = 'Resend Code'; }, 3000);
    }
});

verifyOtpBtn.addEventListener('click', async () => {
    const code = Array.from(otpDigits).map(d => d.value).join('');
    if (code.length !== 6) {
        verifyError.textContent = 'Please enter the full 6-digit code.';
        verifyError.classList.remove('hidden');
        return;
    }

    verifyOtpBtn.disabled = true;
    verifyOtpBtn.textContent = 'Verifying…';

    try {
        await account.createSession(verificationUserId, code);
        isEmailVerified = true;

        // Hide verification, show badge
        verificationSection.classList.add('hidden');
        verifiedBadge.classList.remove('hidden');

        // Enable submit button
        submitBtn.disabled = false;
        submitBtn.querySelector('.btn-text').textContent = 'Submit to Family Vault';
    } catch (e) {
        console.error('OTP verify error:', e);
        verifyError.textContent = 'Invalid code. Please try again.';
        verifyError.classList.remove('hidden');
        verifyOtpBtn.disabled = false;
        verifyOtpBtn.textContent = 'Verify Email';
    }
});

// ═══════════════════════════════════════════════
// MULTI-PHOTO UPLOAD with per-photo voice notes
// ═══════════════════════════════════════════════
const uploadedPhotos = []; // { file, previewUrl, story, audioBlob, audioUrl }

const dropzone = document.getElementById('uploadDropzone');
const photoInput = document.getElementById('photoInput');
const photoGrid = document.getElementById('photoGrid');

// Per-photo active recorder tracking
let activePhotoRecorder = null;
let activePhotoRecorderIdx = null;
let activePhotoInterval = null;

dropzone.addEventListener('click', () => photoInput.click());
dropzone.addEventListener('dragover', (e) => { e.preventDefault(); dropzone.classList.add('drag-over'); });
dropzone.addEventListener('dragleave', () => dropzone.classList.remove('drag-over'));
dropzone.addEventListener('drop', (e) => { e.preventDefault(); dropzone.classList.remove('drag-over'); handleFiles(e.dataTransfer.files); });
photoInput.addEventListener('change', (e) => { handleFiles(e.target.files); photoInput.value = ''; });

function handleFiles(fileList) {
    for (const file of fileList) {
        if (!file.type.startsWith('image/')) continue;
        uploadedPhotos.push({ file, previewUrl: URL.createObjectURL(file), story: '', audioBlob: null, audioUrl: null });
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

    uploadedPhotos.forEach((photo, idx) => {
        const card = document.createElement('div');
        card.className = 'photo-card';
        card.style.animationDelay = `${idx * 0.08}s`;

        const hasAudio = !!photo.audioBlob;

        card.innerHTML = `
            <img src="${photo.previewUrl}" class="photo-card-img" alt="Photo ${idx + 1}">
            <button type="button" class="photo-remove-btn" data-index="${idx}">✕</button>
            <div class="photo-card-body">
                <textarea placeholder="What's the story behind this photo?" data-index="${idx}" class="photo-story-input">${photo.story}</textarea>
            </div>
            <div class="photo-card-audio">
                ${hasAudio ? `
                    <div class="photo-audio-playback">
                        <audio controls src="${photo.audioUrl}"></audio>
                        <button type="button" class="photo-audio-delete" data-index="${idx}">🗑️</button>
                    </div>
                ` : `
                    <button type="button" class="photo-record-btn" data-index="${idx}">
                        🎤 <span>Record voice note</span>
                    </button>
                `}
            </div>
        `;
        photoGrid.appendChild(card);
    });

    // Add More card
    const addMore = document.createElement('div');
    addMore.className = 'add-more-photos';
    addMore.innerHTML = `<span class="add-more-icon">➕</span><span class="add-more-text">Add More Photos</span>`;
    addMore.addEventListener('click', () => photoInput.click());
    photoGrid.appendChild(addMore);

    // Bind events
    photoGrid.querySelectorAll('.photo-remove-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const i = parseInt(btn.dataset.index);
            URL.revokeObjectURL(uploadedPhotos[i].previewUrl);
            uploadedPhotos.splice(i, 1);
            renderPhotoGrid();
        });
    });

    photoGrid.querySelectorAll('.photo-story-input').forEach(ta => {
        ta.addEventListener('input', (e) => {
            uploadedPhotos[parseInt(ta.dataset.index)].story = e.target.value;
        });
    });

    // Per-photo record buttons
    photoGrid.querySelectorAll('.photo-record-btn').forEach(btn => {
        btn.addEventListener('click', async () => {
            const idx = parseInt(btn.dataset.index);
            await startPhotoRecording(idx, btn);
        });
    });

    // Per-photo audio delete
    photoGrid.querySelectorAll('.photo-audio-delete').forEach(btn => {
        btn.addEventListener('click', () => {
            const idx = parseInt(btn.dataset.index);
            uploadedPhotos[idx].audioBlob = null;
            uploadedPhotos[idx].audioUrl = null;
            renderPhotoGrid();
        });
    });
}

async function startPhotoRecording(idx, btn) {
    // If already recording this one, stop
    if (activePhotoRecorderIdx === idx && activePhotoRecorder && activePhotoRecorder.state === 'recording') {
        activePhotoRecorder.stop();
        clearInterval(activePhotoInterval);
        activePhotoRecorderIdx = null;
        return;
    }

    try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        const recorder = new MediaRecorder(stream);
        const chunks = [];

        recorder.ondataavailable = (e) => { if (e.data.size > 0) chunks.push(e.data); };
        recorder.onstop = () => {
            const blob = new Blob(chunks, { type: 'audio/webm' });
            uploadedPhotos[idx].audioBlob = blob;
            uploadedPhotos[idx].audioUrl = URL.createObjectURL(blob);
            stream.getTracks().forEach(t => t.stop());
            renderPhotoGrid();
        };

        recorder.start();
        activePhotoRecorder = recorder;
        activePhotoRecorderIdx = idx;

        btn.classList.add('recording');
        btn.querySelector('span').textContent = 'Stop recording…';

        let secs = 0;
        activePhotoInterval = setInterval(() => {
            secs++;
            btn.querySelector('span').textContent = `Stop (${Math.floor(secs/60)}:${(secs%60).toString().padStart(2,'0')})`;
        }, 1000);

    } catch (err) {
        alert('Please allow microphone access.');
    }
}

// ═══════════════════════════════════════════════
// GENERAL AUDIO RECORDING
// ═══════════════════════════════════════════════
let mediaRecorder, audioChunks = [], audioBlob = null, recordingInterval = null, recordingSeconds = 0;
const recordBtn = document.getElementById('recordBtn');
const recordText = document.getElementById('recordText');
const recordTimer = document.getElementById('recordTimer');
const audioPlaybackContainer = document.getElementById('audioPlaybackContainer');
const audioPlayback = document.getElementById('audioPlayback');
const deleteAudioBtn = document.getElementById('deleteAudioBtn');

recordBtn.addEventListener('click', async () => {
    if (mediaRecorder && mediaRecorder.state === 'recording') {
        mediaRecorder.stop();
        clearInterval(recordingInterval);
        recordBtn.classList.remove('recording');
        recordText.textContent = 'Record General Voice Note';
        recordTimer.classList.add('hidden');
        return;
    }
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        mediaRecorder = new MediaRecorder(stream);
        audioChunks = [];
        recordingSeconds = 0;

        mediaRecorder.ondataavailable = (e) => { if (e.data.size > 0) audioChunks.push(e.data); };
        mediaRecorder.onstop = () => {
            audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
            audioPlayback.src = URL.createObjectURL(audioBlob);
            audioPlaybackContainer.classList.remove('hidden');
            recordBtn.style.display = 'none';
            stream.getTracks().forEach(t => t.stop());
        };

        mediaRecorder.start();
        recordBtn.classList.add('recording');
        recordText.textContent = 'Stop Recording';
        recordTimer.classList.remove('hidden');
        recordingInterval = setInterval(() => {
            recordingSeconds++;
            recordTimer.textContent = `${Math.floor(recordingSeconds/60)}:${(recordingSeconds%60).toString().padStart(2,'0')}`;
        }, 1000);
    } catch (err) {
        alert('Please allow microphone access.');
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

    if (!isEmailVerified) {
        alert('Please verify your email address before submitting.');
        return;
    }

    const storyText = document.getElementById('story').value.trim();
    const hasPhotosWithContent = uploadedPhotos.some(p => p.story.trim() || p.audioBlob);

    if (!storyText && !audioBlob && !hasPhotosWithContent && uploadedPhotos.length === 0) {
        alert('Please write a story, record audio, or add at least one photo!');
        return;
    }

    const btnText = submitBtn.querySelector('.btn-text');
    submitBtn.disabled = true;
    btnText.textContent = 'Preparing…';

    const name = document.getElementById('contributorName').value.trim();
    const relation = document.getElementById('contributorRelation').value.trim();
    const email = document.getElementById('contributorEmail').value.trim();
    const phone = document.getElementById('contributorPhone').value.trim();
    const title = document.getElementById('title').value.trim();

    try {
        // 1. Upload profile photo
        let profilePhotoUrl = null;
        if (profilePhotoFile) {
            btnText.textContent = 'Uploading profile photo…';
            const uploaded = await storage.createFile(BUCKET_ID, Appwrite.ID.unique(), profilePhotoFile);
            profilePhotoUrl = `https://nyc.cloud.appwrite.io/v1/storage/buckets/${BUCKET_ID}/files/${uploaded.$id}/view?project=687e9e6200375f703df2`;
        }

        // 2. Upload general audio
        let generalAudioUrl = null;
        if (audioBlob) {
            btnText.textContent = 'Uploading voice note…';
            const file = new File([audioBlob], `audio_${Date.now()}.webm`, { type: 'audio/webm' });
            const uploaded = await storage.createFile(BUCKET_ID, Appwrite.ID.unique(), file);
            generalAudioUrl = `https://nyc.cloud.appwrite.io/v1/storage/buckets/${BUCKET_ID}/files/${uploaded.$id}/view?project=687e9e6200375f703df2`;
        }

        // 3. Upload photos — each photo = one memory document
        if (uploadedPhotos.length > 0) {
            for (let i = 0; i < uploadedPhotos.length; i++) {
                const photo = uploadedPhotos[i];
                btnText.textContent = `Uploading photo ${i + 1} of ${uploadedPhotos.length}…`;

                // Upload photo file
                const uploaded = await storage.createFile(BUCKET_ID, Appwrite.ID.unique(), photo.file);
                const photoUrl = `https://nyc.cloud.appwrite.io/v1/storage/buckets/${BUCKET_ID}/files/${uploaded.$id}/view?project=687e9e6200375f703df2`;

                // Upload per-photo audio if exists
                let perPhotoAudioUrl = null;
                if (photo.audioBlob) {
                    btnText.textContent = `Uploading voice note for photo ${i + 1}…`;
                    const audioFile = new File([photo.audioBlob], `photo_audio_${Date.now()}_${i}.webm`, { type: 'audio/webm' });
                    const audioUploaded = await storage.createFile(BUCKET_ID, Appwrite.ID.unique(), audioFile);
                    perPhotoAudioUrl = `https://nyc.cloud.appwrite.io/v1/storage/buckets/${BUCKET_ID}/files/${audioUploaded.$id}/view?project=687e9e6200375f703df2`;
                }

                const photoStory = photo.story.trim() || storyText || 'Photo Memory';
                const photoTitle = uploadedPhotos.length > 1 ? `${title} (${i+1}/${uploadedPhotos.length})` : title;

                await databases.createDocument(DATABASE_ID, MEMORIES_COLLECTION, Appwrite.ID.unique(), {
                    userId: currentLink.userId,
                    title: photoTitle,
                    story: photoStory,
                    contributorName: name,
                    contributorRelation: relation,
                    contributorEmail: email,
                    contributorPhone: phone,
                    contributorPhotoUrl: profilePhotoUrl,
                    photoUrl: photoUrl,
                    audioUrl: perPhotoAudioUrl || (i === 0 ? generalAudioUrl : null),
                    isApproved: false,
                    status: 'raw',
                    visibility: 'public'
                });
            }
        } else {
            // 4. No photos — text/audio only
            btnText.textContent = 'Saving memory…';
            await databases.createDocument(DATABASE_ID, MEMORIES_COLLECTION, Appwrite.ID.unique(), {
                userId: currentLink.userId,
                title: title,
                story: storyText || 'Audio Memory',
                contributorName: name,
                contributorRelation: relation,
                contributorEmail: email,
                contributorPhone: phone,
                contributorPhotoUrl: profilePhotoUrl,
                photoUrl: currentLink.type === 'photo_context' ? currentLink.photoUrl : null,
                audioUrl: generalAudioUrl,
                isApproved: false,
                status: 'raw',
                visibility: 'public'
            });
        }

        // Success
        document.getElementById('form-card').classList.add('hidden');
        document.getElementById('success-state').classList.remove('hidden');
        window.scrollTo({ top: 0, behavior: 'smooth' });

    } catch (err) {
        console.error('Submit error:', err);
        alert('Error submitting memory: ' + err.message);
        submitBtn.disabled = false;
        btnText.textContent = 'Submit to Family Vault';
    }
});

// ═══════════════════════════════════════════════
// LAUNCH
// ═══════════════════════════════════════════════
init();
