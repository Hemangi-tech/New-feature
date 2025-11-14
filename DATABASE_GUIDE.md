# Peer Q&A Discussion Forum - Database Guide

## Overview
This guide explains where your data is stored, how to access it, and how to integrate it with your main project.

## Database Information

### Database Type
**Supabase (PostgreSQL)**

Your database is hosted on Supabase at:
- **URL**: `https://wlolwxivgiczdvboyjnq.supabase.co`
- **Project Dashboard**: https://supabase.com/dashboard/project/wlolwxivgiczdvboyjnq

## Database Schema

### Tables Created

#### 1. **questions** table
Stores all submitted questions with user details and vote counts.

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Unique identifier (Primary Key) |
| user_name | text | Name of person asking |
| enrollment_no | text | Enrollment number of asker |
| question_text | text | The question content |
| category | text | Question category (General, Technical, etc.) |
| vote_count | integer | Total number of votes (default: 0) |
| created_at | timestamptz | When question was posted |
| updated_at | timestamptz | Last update timestamp |

#### 2. **answers** table
Stores all answers submitted to questions.

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Unique identifier (Primary Key) |
| question_id | uuid | Links to question (Foreign Key) |
| user_name | text | Name of person answering |
| enrollment_no | text | Enrollment number of answerer |
| answer_text | text | The answer content |
| created_at | timestamptz | When answer was posted |

#### 3. **votes** table
Tracks who voted on which questions (prevents duplicate votes).

| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Unique identifier (Primary Key) |
| question_id | uuid | Links to question (Foreign Key) |
| user_identifier | text | Enrollment number of voter |
| voted_at | timestamptz | When vote was cast |

**Important**: The combination of `question_id` and `user_identifier` is unique, preventing duplicate votes.

## How to Access Your Database

### Option 1: Supabase Dashboard (Recommended for Quick Access)

1. **Login to Supabase**
   - Go to https://supabase.com/dashboard
   - Login with your account

2. **Navigate to Your Project**
   - Select project: `wlolwxivgiczdvboyjnq`

3. **View Tables**
   - Click on "Table Editor" in the left sidebar
   - You'll see all three tables: questions, answers, votes
   - Click any table to view/edit data

4. **Export Data**
   - Click on any table
   - Click the "..." menu button
   - Select "Download as CSV" to export data

### Option 2: SQL Editor (For Custom Queries)

1. In Supabase Dashboard, click "SQL Editor"
2. Run queries like:

```sql
-- Get all questions with answer counts
SELECT
  q.*,
  COUNT(a.id) as answer_count
FROM questions q
LEFT JOIN answers a ON a.question_id = q.id
GROUP BY q.id
ORDER BY q.vote_count DESC;

-- Get all answers for a specific question
SELECT * FROM answers
WHERE question_id = 'your-question-id'
ORDER BY created_at DESC;

-- Get voting statistics
SELECT
  q.question_text,
  q.vote_count,
  COUNT(v.id) as verified_votes
FROM questions q
LEFT JOIN votes v ON v.question_id = q.id
GROUP BY q.id
ORDER BY q.vote_count DESC;
```

### Option 3: Direct Database Connection

You can connect directly using PostgreSQL tools:

1. Get connection string from Supabase Dashboard:
   - Settings → Database → Connection String

2. Use tools like:
   - **pgAdmin**: GUI database manager
   - **DBeaver**: Universal database tool
   - **psql**: Command-line PostgreSQL client

## How to Download Your Data

### Method 1: CSV Export from Dashboard
1. Open Supabase Dashboard
2. Go to Table Editor
3. Select each table (questions, answers, votes)
4. Click "..." → "Download as CSV"

### Method 2: Using SQL Query
```sql
-- Export questions as JSON
COPY (
  SELECT row_to_json(q)
  FROM questions q
) TO STDOUT;
```

### Method 3: Using Supabase API
```javascript
import { supabase } from './lib/supabase';

async function exportAllData() {
  // Export questions
  const { data: questions } = await supabase
    .from('questions')
    .select('*');

  // Export answers
  const { data: answers } = await supabase
    .from('answers')
    .select('*');

  // Export votes
  const { data: votes } = await supabase
    .from('votes')
    .select('*');

  // Download as JSON files
  downloadJSON(questions, 'questions.json');
  downloadJSON(answers, 'answers.json');
  downloadJSON(votes, 'votes.json');
}
```

## How to Integrate with Your Main Project

### Option 1: Use Same Database (Recommended)

Your current forum already uses this database. Simply deploy it as part of Study Sphere:

1. **Keep the same `.env` file** with your Supabase credentials
2. **Copy these files** to your main project:
   - `src/lib/supabase.js`
   - `src/services/forumService.js`
   - `src/components/` (all forum components)

3. **Import and use** in your main app:
```javascript
import ForumApp from './pages/Forum';

// In your routing
<Route path="/forum" element={<ForumApp />} />
```

### Option 2: Create New Database in Your Project

If you want to use a different database:

1. **Export the migration SQL**:
   - The complete schema is in the migration file created
   - Copy the SQL from `supabase/migrations/create_peer_qa_forum_schema.sql`

2. **Run on your database**:
   ```bash
   psql -U your_user -d your_database -f migration.sql
   ```

3. **Update connection details** in `.env`:
   ```
   VITE_SUPABASE_URL=your_new_database_url
   VITE_SUPABASE_ANON_KEY=your_new_api_key
   ```

### Option 3: Migrate Data to Another System

1. **Export data** using any method above
2. **Transform data** to your schema format
3. **Import** using your database's import tools

## Database Connection Details

The connection is configured in `.env`:
```
VITE_SUPABASE_URL=https://wlolwxivgiczdvboyjnq.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Important**: This anon key is safe to use in frontend code. It allows public access which is required for this open forum.

## Features Built Into the Database

### 1. Automatic Vote Prevention
- Unique constraint prevents duplicate votes
- One user = one vote per question

### 2. Cascading Deletes
- Deleting a question automatically deletes its answers and votes
- Maintains data integrity

### 3. Automatic Timestamps
- `created_at` and `updated_at` are automatically set
- No manual date management needed

### 4. Public Access (No Authentication Required)
- Row Level Security (RLS) enabled but allows public access
- Anyone can ask, answer, and vote
- Perfect for open learning platform

### 5. Indexed for Performance
- Vote count indexed for fast sorting
- Category indexed for filtering
- Optimized queries

## API Usage Examples

### Fetch All Questions
```javascript
import { forumService } from './services/forumService';

const questions = await forumService.getQuestions();
```

### Add a Question
```javascript
await forumService.addQuestion({
  userName: 'John Doe',
  enrollmentNo: '12345',
  questionText: 'How does React work?',
  category: 'Technical'
});
```

### Vote on a Question
```javascript
await forumService.voteQuestion(questionId, userEnrollment);
```

### Add an Answer
```javascript
await forumService.addAnswer({
  questionId: 'question-uuid',
  userName: 'Jane Smith',
  enrollmentNo: '67890',
  answerText: 'React is a JavaScript library...'
});
```

## Backup and Maintenance

### Automatic Backups
Supabase automatically backs up your database daily.

### Manual Backup
1. Go to Supabase Dashboard
2. Settings → Database → Backups
3. Click "Create backup"

### Database Monitoring
- Check "Database" section for performance metrics
- View "Logs" for any errors
- Monitor "API" usage

## Support and Documentation

- **Supabase Docs**: https://supabase.com/docs
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **Project Dashboard**: https://supabase.com/dashboard/project/wlolwxivgiczdvboyjnq

## Security Notes

1. **Public Access is Intentional**: This forum is designed for open use without login
2. **RLS is Enabled**: Even with public access, RLS provides structure and protection
3. **No Sensitive Data**: Never store passwords or sensitive information in this open forum
4. **Rate Limiting**: Supabase provides automatic rate limiting to prevent abuse

## Next Steps

1. ✅ Your database is set up and ready
2. ✅ All tables are created with proper relationships
3. ✅ Data is being saved automatically
4. ✅ You can access it anytime via Supabase Dashboard
5. 📌 Integrate into your main Study Sphere project using Option 1 above
6. 📌 Add custom analytics or reporting as needed
7. 📌 Consider adding moderation features if needed

Your forum is production-ready and all data is securely stored in Supabase PostgreSQL database!
