# Task Board Implementation Design

## Overview

The Task Board is a modern task management application that replicates the macOS desktop experience. Users create and organize tasks using draggable sticky notes on a freeform canvas, with Git integration and Supabase backend services for real-time collaboration and data persistence.

### Core Features
- **Freeform Canvas**: Sticky note tasks positioned anywhere on the board
- **Drag & Drop Interface**: Seamless task repositioning similar to macOS desktop icons
- **Priority-Based Color Coding**: Green (low), Yellow (medium), Red (high priority)
- **Hidden Control Panel**: macOS-style dock appearing on hover at screen edge
- **Task Expansion**: Click to expand notes for detailed editing and commenting
- **Real-time Synchronization**: Cross-session persistence via Supabase

## Technology Stack & Dependencies

### Frontend Stack
- **Framework**: React 18 with TypeScript
- **Styling**: Tailwind CSS
- **Drag & Drop**: React DnD library
- **State Management**: Zustand
- **Animation**: Framer Motion

### Backend & Services
- **Backend-as-a-Service**: Supabase
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth
- **Real-time Updates**: Supabase real-time subscriptions

### Development Tools
- **Build Tool**: Vite
- **Version Control**: Git integration
- **Package Manager**: npm/yarn

## Architecture

### Component Architecture

```mermaid
graph TD
    A[App Component] --> B[Authentication Wrapper]
    B --> C[Task Board Container]
    C --> D[Canvas Area]
    C --> E[Control Panel]
    D --> F[Sticky Note Components]
    D --> G[Drag Layer]
    E --> H[Create Task Button]
    E --> I[Organization Tools]
    E --> J[User Profile]
    F --> K[Task Detail Modal]
    F --> L[Priority Indicator]
    F --> M[Task Content]
```

#### Component Definitions

**App Component**
- Root component managing global application state and Supabase client initialization
- Handles routing and top-level error boundaries

**Authentication Wrapper**
- Manages user authentication state and login/logout flows
- Protects authenticated routes

**Task Board Container**
- Main workspace component managing board state and task positions
- Handles real-time synchronization with Supabase

**Canvas Area**
- Freeform workspace implementing drag-and-drop zones
- Manages coordinate system for task positioning

**Sticky Note Components**
- Individual task representation with drag interactions
- Manages priority color display and visual feedback

**Control Panel**
- Hidden dock-style interface appearing on mouse hover
- Contains task creation and organization tools

**Task Detail Modal**
- Expanded view for task editing with description, comments, and metadata
- Provides delete and archive functionality

### Data Flow Architecture

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant S as Supabase
    participant D as Database
    
    U->>F: Create/Move Task
    F->>S: Update Task Position
    S->>D: Persist Changes
    S->>F: Real-time Update
    F->>U: Visual Feedback
    
    U->>F: Click to Expand Task
    F->>F: Open Task Modal
    U->>F: Edit Task Details
    F->>S: Save Changes
    S->>D: Update Database
    S->>F: Confirm Update
```

## Data Models & Database Schema

### Tasks Table
| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | Primary key | NOT NULL, DEFAULT uuid_generate_v4() |
| user_id | UUID | Owner reference | NOT NULL, FOREIGN KEY |
| title | TEXT | Task title | NOT NULL, LENGTH 1-100 |
| description | TEXT | Detailed description | OPTIONAL |
| priority | ENUM | Priority level | LOW, MEDIUM, HIGH |
| position_x | INTEGER | X coordinate on canvas | NOT NULL, DEFAULT 0 |
| position_y | INTEGER | Y coordinate on canvas | NOT NULL, DEFAULT 0 |
| color | VARCHAR(7) | Hex color code | NOT NULL, DEFAULT based on priority |
| created_at | TIMESTAMP | Creation timestamp | NOT NULL, DEFAULT NOW() |
| updated_at | TIMESTAMP | Last modification | NOT NULL, DEFAULT NOW() |
| is_archived | BOOLEAN | Archive status | NOT NULL, DEFAULT FALSE |

### Comments Table
| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | Primary key | NOT NULL, DEFAULT uuid_generate_v4() |
| task_id | UUID | Task reference | NOT NULL, FOREIGN KEY |
| user_id | UUID | Comment author | NOT NULL, FOREIGN KEY |
| content | TEXT | Comment content | NOT NULL, LENGTH 1-500 |
| created_at | TIMESTAMP | Creation timestamp | NOT NULL, DEFAULT NOW() |

### User Profiles Table
| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| id | UUID | Primary key | NOT NULL, REFERENCES auth.users |
| email | TEXT | User email | NOT NULL, UNIQUE |
| display_name | TEXT | Display name | OPTIONAL |
| avatar_url | TEXT | Profile picture URL | OPTIONAL |
| created_at | TIMESTAMP | Registration date | NOT NULL, DEFAULT NOW() |

## User Interface Design

### Canvas Interaction Model

**Freeform Placement**
- Tasks positioned anywhere within canvas boundaries using pixel-based coordinates
- Optional grid snap functionality and zoom/pan capabilities for large boards

**Drag & Drop Behavior**
- Smooth drag initiation with visual lift effect and real-time position updates
- Collision detection to prevent overlapping with optional snap-to-grid

### Priority Color System

| Priority | Color Code | Visual Representation |
|----------|------------|----------------------|
| Low | #10B981 (Green) | Soft green sticky note |
| Medium | #F59E0B (Yellow) | Warm yellow sticky note |
| High | #EF4444 (Red) | Alert red sticky note |

### Control Panel Design

**macOS-Style Dock Interface**
- Hidden by default, appears with smooth animation on mouse hover
- Translucent background with blur effect, rounded corners and shadow

**Control Elements**
- **Add Task Button**: Plus icon to create new sticky notes
- **Organization Tools**: Grid view, list view toggle
- **Search Function**: Quick task filtering
- **User Profile**: Avatar and account settings
- **Board Settings**: Canvas preferences and export options

## Authentication Flow

```mermaid
stateDiagram-v2
    [*] --> Unauthenticated
    Unauthenticated --> LoginPage : Navigate to app
    LoginPage --> Authenticating : Submit credentials
    Authenticating --> Authenticated : Success
    Authenticating --> LoginPage : Error
    Authenticated --> TaskBoard : Access granted
    TaskBoard --> Unauthenticated : Logout
    
    LoginPage --> SignupPage : New user
    SignupPage --> Authenticating : Register
```

### Authentication Methods
- **Email/Password**: Traditional authentication with Supabase Auth
- **Social Login**: Google, GitHub integration options
- **Session Management**: Automatic token refresh and secure storage
- **Password Recovery**: Email-based password reset flow

## Real-time Collaboration Features

### Live Updates
- Task position changes broadcast to all connected users
- New task creation notifications and real-time comment additions
- User presence indicators

### Conflict Resolution
- Last-write-wins strategy for task updates
- Optimistic UI updates with rollback capability
- Connection state management for offline scenarios

## State Management Strategy

### Zustand Store Structure

**Tasks Store**
- Task collection with CRUD operations
- Position tracking and update methods
- Priority filtering and sorting functions
- Real-time subscription management

**UI Store**
- Control panel visibility state
- Selected task tracking
- Modal and overlay management
- Canvas view preferences

**Auth Store**
- User authentication state
- Profile information
- Session management
- Permission handling

## API Integration Layer

### Supabase Integration Patterns

**Task Operations**
- CREATE: Insert new task with generated position
- READ: Fetch user's tasks with real-time subscription
- UPDATE: Modify task properties and position
- DELETE: Soft delete with archive functionality

**Real-time Subscriptions**
- Task table changes for live updates
- Comment additions for expanded tasks
- User presence for collaboration features

### Error Handling Strategy
- Network error recovery with retry logic
- Optimistic updates with rollback capability
- User-friendly error messages
- Offline state management

## Testing

### Unit Testing
- Component rendering and interaction tests
- State management logic validation
- Utility function verification
- Drag and drop behavior testing

### Integration Testing
- Supabase client integration
- Authentication flow testing
- Real-time subscription functionality
- Cross-component communication

### End-to-End Testing
- Complete user workflows
- Multi-user collaboration scenarios
- Responsive design validation
- Performance under load

### Testing Tools
- **Jest**: Unit and integration testing framework
- **React Testing Library**: Component testing utilities
- **Cypress**: End-to-end testing automation
- **MSW**: API mocking for isolated testing