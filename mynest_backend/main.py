"""
MyNest Backend V1.2.0 — Appwrite Serverless Function
Deploy to Appwrite Functions as a Python runtime.

Handles:
- Link generation & resolution
- Memory approval workflow
- Family tree organization via Gemini AI
- Profile management
"""

import json
import os
import hashlib
import time
from appwrite.client import Client
from appwrite.services.databases import Databases
from appwrite.services.storage import Storage
from appwrite.services.users import Users
from appwrite.id import ID
from appwrite.query import Query


# ── Config ──
DATABASE_ID = os.environ.get('APPWRITE_DATABASE_ID', 'YOUR_DATABASE_ID')
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', '')
GEMINI_MODEL = 'gemini-3.1-flash-live-preview'


def main(context):
    """Appwrite Function entry point."""
    client = Client()
    client.set_endpoint(os.environ.get('APPWRITE_FUNCTION_API_ENDPOINT', 'https://cloud.appwrite.io/v1'))
    client.set_project(os.environ.get('APPWRITE_FUNCTION_PROJECT_ID', ''))
    client.set_key(os.environ.get('APPWRITE_API_KEY', ''))

    db = Databases(client)
    storage = Storage(client)
    users = Users(client)

    # Parse the request
    try:
        body = json.loads(context.req.body) if context.req.body else {}
    except Exception:
        body = {}

    path = context.req.path or '/'
    method = context.req.method or 'GET'

    # ── Route Handler ──
    try:
        if path == '/link/create' and method == 'POST':
            return _create_link(context, db, body)
        elif path.startswith('/link/resolve/') and method == 'GET':
            link_id = path.split('/')[-1]
            return _resolve_link(context, db, link_id)
        elif path == '/memory/approve' and method == 'POST':
            return _approve_memory(context, db, body)
        elif path == '/memory/submit' and method == 'POST':
            return _submit_memory(context, db, body)
        elif path == '/family/organize' and method == 'POST':
            return _organize_tree(context, db, body)
        elif path == '/profile/update' and method == 'POST':
            return _update_profile(context, db, body)
        elif path == '/health' and method == 'GET':
            return context.res.json({
                'status': 'ok',
                'version': '1.2.0',
                'timestamp': int(time.time())
            })
        else:
            return context.res.json({'error': 'Not found'}, 404)
    except Exception as e:
        context.error(str(e))
        return context.res.json({'error': str(e)}, 500)


def _create_link(context, db, body):
    """Create a share link (empty, photo_context, or vault_share)."""
    user_id = body.get('userId')
    link_type = body.get('type', 'empty')
    photo_url = body.get('photoUrl')
    description = body.get('description', '')

    if not user_id:
        return context.res.json({'error': 'userId required'}, 400)

    doc = db.create_document(
        database_id=DATABASE_ID,
        collection_id='links',
        document_id=ID.unique(),
        data={
            'userId': user_id,
            'type': link_type,
            'photoUrl': photo_url,
            'description': description,
            'isActive': True,
        }
    )

    web_domain = os.environ.get('WEB_DOMAIN', 'https://mynest.mursalin.engineer')
    type_prefix = {
        'empty': 'contribute',
        'photo_context': 'photo-story',
        'vault_share': 'vault'
    }.get(link_type, 'contribute')

    return context.res.json({
        'linkId': doc['$id'],
        'url': f"{web_domain}/{type_prefix}/{doc['$id']}",
        'type': link_type,
    })


def _resolve_link(context, db, link_id):
    """Resolve a share link to get its data."""
    try:
        doc = db.get_document(
            database_id=DATABASE_ID,
            collection_id='links',
            document_id=link_id
        )

        if not doc['isActive']:
            return context.res.json({'error': 'Link expired'}, 410)

        result = {
            'type': doc['type'],
            'userId': doc['userId'],
            'isActive': doc['isActive'],
        }

        if doc['type'] == 'photo_context' and doc.get('photoUrl'):
            result['photoUrl'] = doc['photoUrl']

        if doc['type'] == 'vault_share':
            # Fetch public approved memories for this user
            memories = db.list_documents(
                database_id=DATABASE_ID,
                collection_id='memories',
                queries=[
                    Query.equal('userId', doc['userId']),
                    Query.equal('isApproved', True),
                    Query.equal('visibility', 'public'),
                    Query.limit(100)
                ]
            )
            result['memories'] = [
                {
                    'title': m['title'],
                    'story': m.get('story', ''),
                    'eventDate': m.get('eventDate'),
                    'contributorName': m.get('contributorName'),
                }
                for m in memories['documents']
            ]

        return context.res.json(result)

    except Exception:
        return context.res.json({'error': 'Link not found'}, 404)


def _submit_memory(context, db, body):
    """Submit a memory from a public link (pending approval)."""
    user_id = body.get('userId')  # The owner of the link
    title = body.get('title', 'Untitled Memory')
    story = body.get('story', '')
    contributor_name = body.get('contributorName', 'Anonymous')
    contributor_relation = body.get('contributorRelation', '')
    photo_url = body.get('photoUrl')
    event_date = body.get('eventDate')
    location = body.get('location')

    if not user_id:
        return context.res.json({'error': 'userId required'}, 400)

    doc = db.create_document(
        database_id=DATABASE_ID,
        collection_id='memories',
        document_id=ID.unique(),
        data={
            'userId': user_id,
            'title': title,
            'story': story,
            'contributorName': contributor_name,
            'contributorRelation': contributor_relation,
            'photoUrl': photo_url,
            'eventDate': event_date,
            'location': location,
            'isApproved': False,  # Pending approval
            'status': 'raw',
            'visibility': 'public',
        }
    )

    return context.res.json({
        'memoryId': doc['$id'],
        'status': 'pending_approval',
        'message': f'Memory submitted by {contributor_name}. Awaiting family approval.'
    })


def _approve_memory(context, db, body):
    """Approve or reject a pending memory."""
    memory_id = body.get('memoryId')
    action = body.get('action', 'approve')  # 'approve' or 'reject'

    if not memory_id:
        return context.res.json({'error': 'memoryId required'}, 400)

    if action == 'approve':
        db.update_document(
            database_id=DATABASE_ID,
            collection_id='memories',
            document_id=memory_id,
            data={'isApproved': True, 'status': 'chaptered'}
        )
        return context.res.json({'status': 'approved'})
    else:
        db.delete_document(
            database_id=DATABASE_ID,
            collection_id='memories',
            document_id=memory_id
        )
        return context.res.json({'status': 'rejected'})


def _organize_tree(context, db, body):
    """Use Gemini AI to organize the family tree structure."""
    user_id = body.get('userId')
    if not user_id:
        return context.res.json({'error': 'userId required'}, 400)

    # Fetch all family members
    members = db.list_documents(
        database_id=DATABASE_ID,
        collection_id='family_members',
        queries=[
            Query.equal('userId', user_id),
            Query.equal('isApproved', True),
            Query.limit(100)
        ]
    )

    member_list = [
        {
            'id': m['$id'],
            'name': m['fullName'],
            'relation': m.get('relation', ''),
            'gender': m.get('gender', ''),
            'dateOfBirth': m.get('dateOfBirth', ''),
            'isDeceased': m.get('isDeceased', False),
        }
        for m in members['documents']
    ]

    # If Gemini API key is available, use AI to organize
    if GEMINI_API_KEY:
        try:
            organized = _gemini_organize(member_list)
            return context.res.json(organized)
        except Exception as e:
            context.error(f"Gemini error: {e}")

    # Fallback: keyword-based organization
    layers = {
        'grandparents': [],
        'parents': [],
        'self': [],
        'siblings': [],
        'children': [],
        'extended': [],
    }

    for m in member_list:
        r = (m.get('relation') or '').lower()
        if any(k in r for k in ['grandm', 'grandf', 'grandp', 'nana', 'nani', 'dada', 'dadi']):
            layers['grandparents'].append(m)
        elif any(k in r for k in ['mother', 'father', 'mom', 'dad', 'amma', 'abba', 'parent']):
            layers['parents'].append(m)
        elif any(k in r for k in ['self', 'me', 'admin']):
            layers['self'].append(m)
        elif any(k in r for k in ['sister', 'brother', 'sibling', 'bhai', 'behen']):
            layers['siblings'].append(m)
        elif any(k in r for k in ['son', 'daughter', 'child', 'kid', 'beta', 'beti']):
            layers['children'].append(m)
        else:
            layers['extended'].append(m)

    return context.res.json({'layers': layers, 'source': 'keyword'})


def _gemini_organize(member_list):
    """Call Gemini 3.1 Flash to intelligently organize the family tree."""
    import urllib.request

    prompt = f"""You are a family tree organizer. Given the following list of family members,
organize them into a hierarchical family tree structure.

Members:
{json.dumps(member_list, indent=2)}

Return a JSON object with these keys:
- "layers": an object with keys "grandparents", "parents", "self", "siblings", "children", "extended"
  Each key maps to a list of member IDs belonging to that generation.
- "connections": a list of objects like {{"from": "id1", "to": "id2", "type": "parent-child"}}

Only return the JSON, no explanation."""

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}"
    
    payload = json.dumps({
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.1}
    }).encode('utf-8')

    req = urllib.request.Request(url, data=payload, headers={
        'Content-Type': 'application/json'
    })

    with urllib.request.urlopen(req, timeout=30) as response:
        result = json.loads(response.read().decode('utf-8'))
        text = result['candidates'][0]['content']['parts'][0]['text']
        
        # Clean the response (remove markdown code blocks if present)
        text = text.strip()
        if text.startswith('```'):
            text = text.split('\n', 1)[1]
        if text.endswith('```'):
            text = text.rsplit('```', 1)[0]
        
        return json.loads(text.strip())


def _update_profile(context, db, body):
    """Update user profile."""
    user_id = body.get('userId')
    data = {}

    for field in ['displayName', 'familyName', 'profilePhotoUrl', 'bio']:
        if field in body:
            data[field] = body[field]

    if not user_id or not data:
        return context.res.json({'error': 'userId and at least one field required'}, 400)

    # Find existing profile
    existing = db.list_documents(
        database_id=DATABASE_ID,
        collection_id='users',
        queries=[Query.equal('userId', user_id), Query.limit(1)]
    )

    if existing['documents']:
        doc_id = existing['documents'][0]['$id']
        db.update_document(
            database_id=DATABASE_ID,
            collection_id='users',
            document_id=doc_id,
            data=data
        )
    else:
        data['userId'] = user_id
        db.create_document(
            database_id=DATABASE_ID,
            collection_id='users',
            document_id=ID.unique(),
            data=data
        )

    return context.res.json({'status': 'updated'})
