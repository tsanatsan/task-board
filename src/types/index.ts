export type Priority = 'low' | 'medium' | 'high'

export interface Task {
  id: string
  user_id: string
  title: string
  description?: string
  priority: Priority
  position_x: number
  position_y: number
  color: string
  created_at: string
  updated_at: string
  is_archived: boolean
}

export interface Comment {
  id: string
  task_id: string
  user_id: string
  content: string
  created_at: string
}

export interface UserProfile {
  id: string
  email: string
  display_name?: string
  avatar_url?: string
  created_at: string
}

export interface TaskPosition {
  x: number
  y: number
}

export interface DragItem {
  type: string
  id: string
  task: Task
}