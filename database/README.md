# Database Setup Instructions

## Prerequisites
1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from Project Settings > API

## Setup Steps

### 1. Update Environment Variables
Copy `.env.example` to `.env` and update with your Supabase credentials:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 2. Run Database Schema
1. Open your Supabase dashboard
2. Go to SQL Editor
3. Copy and paste the contents of `database/schema.sql`
4. Click "Run" to execute the schema

### 3. Enable Real-time (Optional)
1. Go to Database > Replication in your Supabase dashboard
2. Enable real-time for the following tables:
   - `tasks`
   - `comments`
   - `user_profiles`

## Database Structure

### Tables Created:
- **user_profiles**: User account information
- **tasks**: Task data with position and priority
- **comments**: Task comments and notes

### Features Enabled:
- Row Level Security (RLS) for data protection
- Automatic user profile creation on signup
- Priority-based color assignment
- Real-time subscriptions for live updates
- Optimized indexes for performance

## Authentication
The app uses Supabase Auth with email/password authentication. User profiles are automatically created when users sign up.