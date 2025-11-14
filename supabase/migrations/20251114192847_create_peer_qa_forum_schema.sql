/*
  # Peer Q&A Discussion Forum Schema
  
  ## Overview
  Creates a collaborative learning platform where users can ask questions, answer questions, and vote on content without authentication.
  
  ## Tables Created
  
  ### 1. questions
  - `id` (uuid, primary key) - Unique identifier for each question
  - `user_name` (text) - Name of the person asking the question
  - `enrollment_no` (text) - Enrollment number of the asker
  - `question_text` (text) - The actual question content
  - `category` (text) - Question category (General, Technical, Academic, etc.)
  - `vote_count` (integer) - Total number of votes received
  - `created_at` (timestamptz) - When the question was posted
  - `updated_at` (timestamptz) - Last update timestamp
  
  ### 2. answers
  - `id` (uuid, primary key) - Unique identifier for each answer
  - `question_id` (uuid, foreign key) - Links to the question being answered
  - `user_name` (text) - Name of the person answering
  - `enrollment_no` (text) - Enrollment number of the answerer
  - `answer_text` (text) - The actual answer content
  - `created_at` (timestamptz) - When the answer was posted
  
  ### 3. votes
  - `id` (uuid, primary key) - Unique identifier for each vote
  - `question_id` (uuid, foreign key) - Links to the voted question
  - `user_identifier` (text) - Unique identifier for the voter (enrollment_no)
  - `voted_at` (timestamptz) - When the vote was cast
  - Unique constraint on (question_id, user_identifier) to prevent duplicate votes
  
  ## Security
  - RLS enabled on all tables
  - Public access allowed for reading (anyone can view)
  - Public access allowed for inserting (anyone can post/vote)
  - Prevents duplicate votes through unique constraint
  
  ## Notes
  - Questions are sorted by vote_count (highest first)
  - One user can only vote once per question
  - No authentication required - open forum design
  - All timestamps in UTC timezone
*/

-- Create questions table
CREATE TABLE IF NOT EXISTS questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_name text NOT NULL,
  enrollment_no text NOT NULL,
  question_text text NOT NULL,
  category text DEFAULT 'General',
  vote_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create answers table
CREATE TABLE IF NOT EXISTS answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  user_name text NOT NULL,
  enrollment_no text NOT NULL,
  answer_text text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create votes table with duplicate prevention
CREATE TABLE IF NOT EXISTS votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  user_identifier text NOT NULL,
  voted_at timestamptz DEFAULT now(),
  UNIQUE(question_id, user_identifier)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_questions_vote_count ON questions(vote_count DESC);
CREATE INDEX IF NOT EXISTS idx_questions_created_at ON questions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category);
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_votes_question_id ON votes(question_id);
CREATE INDEX IF NOT EXISTS idx_votes_user_identifier ON votes(user_identifier);

-- Enable Row Level Security
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- Questions policies: Allow anyone to read and insert
CREATE POLICY "Anyone can view questions"
  ON questions FOR SELECT
  USING (true);

CREATE POLICY "Anyone can ask questions"
  ON questions FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update question vote counts"
  ON questions FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Answers policies: Allow anyone to read and insert
CREATE POLICY "Anyone can view answers"
  ON answers FOR SELECT
  USING (true);

CREATE POLICY "Anyone can post answers"
  ON answers FOR INSERT
  WITH CHECK (true);

-- Votes policies: Allow anyone to read and insert
CREATE POLICY "Anyone can view votes"
  ON votes FOR SELECT
  USING (true);

CREATE POLICY "Anyone can vote"
  ON votes FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can remove their votes"
  ON votes FOR DELETE
  USING (true);

-- Function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on questions
DROP TRIGGER IF EXISTS update_questions_updated_at ON questions;
CREATE TRIGGER update_questions_updated_at
  BEFORE UPDATE ON questions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();