# Task Board - macOS-Style Sticky Notes App

A modern task management application that replicates the macOS desktop experience with draggable sticky notes on a freeform canvas. Built with React, TypeScript, Supabase, and Framer Motion.

## Features

- 🖱️ **Freeform Canvas**: Drag and position sticky notes anywhere on the board
- 🎨 **Priority-Based Colors**: Green (low), Yellow (medium), Red (high priority)
- 🏠 **macOS-Style Dock**: Hidden control panel that appears on hover
- ✏️ **Expandable Tasks**: Click notes to edit details and add descriptions
- 🔄 **Real-time Sync**: Live updates across sessions with Supabase
- 🔐 **User Authentication**: Secure login with email/password
- 📱 **Responsive Design**: Works on desktop and mobile devices

## Technology Stack

- **Frontend**: React 18 + TypeScript + Vite
- **Styling**: Tailwind CSS
- **Animations**: Framer Motion
- **Drag & Drop**: React DnD
- **State Management**: Zustand
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)

## Quick Start

### 1. Clone and Install

```bash
git clone <repository-url>
cd task-board
npm install
```

### 2. Set Up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Copy `.env.example` to `.env` and add your credentials:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Set Up Database

1. Go to your Supabase dashboard → SQL Editor
2. Copy and paste the contents of `database/schema.sql`
3. Click "Run" to create tables and policies

### 4. Start Development Server

```bash
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) to view the app.

## Usage Guide

### Creating Tasks

- **Quick Create**: Hover over the canvas to reveal the dock, click the ➕ button
- **Detailed Create**: Click the 📝 button for the full task creation modal
- **Priority Selection**: Choose from Low (Green), Medium (Yellow), or High (Red) priority

### Managing Tasks

- **Move Tasks**: Drag sticky notes to reposition them on the canvas
- **Edit Tasks**: Click any sticky note to open the detailed editor
- **Delete Tasks**: Open a task and click "Delete Task"

### Interface

- **Hidden Dock**: Control panel appears when you hover near the bottom of the screen
- **User Profile**: Shows your email and avatar in the dock
- **Real-time Updates**: Changes sync automatically across all your devices

## Project Structure

```
src/
├── components/          # React components
│   ├── AuthForm.tsx     # Login/signup form
│   ├── AuthWrapper.tsx  # Authentication wrapper
│   ├── Canvas.tsx       # Main drag-drop canvas
│   ├── ControlPanel.tsx # macOS-style dock
│   ├── StickyNote.tsx   # Individual task component
│   ├── TaskModal.tsx    # Task editing modal
│   └── ...
├── stores/              # Zustand state management
│   ├── auth.ts          # Authentication state
│   ├── tasks.ts         # Task management state
│   └── ui.ts            # UI state
├── types/               # TypeScript type definitions
├── lib/                 # Utilities and configurations
└── hooks/               # Custom React hooks
```

## Database Schema

The app uses three main tables:

- **tasks**: Task data with position, priority, and content
- **user_profiles**: User account information  
- **comments**: Task comments (future feature)

See `database/schema.sql` for complete schema and security policies.

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

### Environment Variables

| Variable | Description |
|----------|-------------|
| `VITE_SUPABASE_URL` | Your Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Your Supabase anonymous key |

## Deployment

### Production Build

```bash
npm run build
```

The build artifacts will be stored in the `dist/` directory.

### Deploy to Vercel

1. Push your code to GitHub
2. Connect your repository to Vercel
3. Add environment variables in Vercel dashboard
4. Deploy!

### Deploy to Netlify

1. Build the project: `npm run build`
2. Upload the `dist/` folder to Netlify
3. Configure environment variables

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -am 'Add feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

If you encounter any issues:

1. Check the [database setup guide](database/README.md)
2. Ensure environment variables are correctly configured
3. Verify Supabase project is properly configured with RLS policies

## Roadmap

- [ ] Collaborative boards (multi-user)
- [ ] Task comments and attachments
- [ ] Board templates and themes
- [ ] Mobile app (React Native)
- [ ] Offline support with sync
- [ ] Advanced search and filtering