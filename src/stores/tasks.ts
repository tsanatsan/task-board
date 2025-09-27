import { create } from 'zustand'
import { Task, Priority, TaskPosition } from '../types'
import { supabase } from '../lib/supabase'

interface TasksState {
  tasks: Task[]
  loading: boolean
  error: string | null
  selectedTask: Task | null
  
  // Actions
  fetchTasks: () => Promise<void>
  createTask: (title: string, position: TaskPosition, priority?: Priority) => Promise<Task | null>
  updateTask: (id: string, updates: Partial<Task>) => Promise<void>
  updateTaskPosition: (id: string, position: TaskPosition) => Promise<void>
  deleteTask: (id: string) => Promise<void>
  selectTask: (task: Task | null) => void
  setTasks: (tasks: Task[]) => void
  addTask: (task: Task) => void
  removeTask: (id: string) => void
}

const priorityColors = {
  low: '#C8F7C5',    // Пастельно-зеленый
  medium: '#FFF2CC', // Пастельно-желтый
  high: '#FFD5D5'    // Пастельно-розовый
}

export const useTasksStore = create<TasksState>((set) => ({
  tasks: [],
  loading: false,
  error: null,
  selectedTask: null,

  fetchTasks: async () => {
    set({ loading: true, error: null })
    try {
      const { data, error } = await supabase
        .from('tasks')
        .select('*')
        .eq('is_archived', false)
        .order('created_at', { ascending: false })

      if (error) {
        set({ error: error.message, loading: false })
        return
      }

      set({ tasks: data || [], loading: false })
    } catch (error) {
      set({ error: 'Failed to fetch tasks', loading: false })
    }
  },

  createTask: async (title: string, position: TaskPosition, priority: Priority = 'medium') => {
    console.log('Creating task:', { title, position, priority })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      console.log('Current user:', user)
      if (!user) {
        console.error('User not authenticated')
        set({ error: 'User not authenticated' })
        return null
      }

      const newTask = {
        user_id: user.id,
        title,
        priority,
        position_x: position.x,
        position_y: position.y,
        color: priorityColors[priority],
        is_archived: false
      }

      console.log('Inserting task:', newTask)
      const { data, error } = await supabase
        .from('tasks')
        .insert(newTask)
        .select()
        .single()

      if (error) {
        console.error('Database error:', error)
        set({ error: error.message })
        return null
      }

      console.log('Task created successfully:', data)
      const task = data as Task
      set(state => ({ tasks: [task, ...state.tasks] }))
      return task
    } catch (error) {
      console.error('Create task error:', error)
      set({ error: 'Failed to create task' })
      return null
    }
  },

  updateTask: async (id: string, updates: Partial<Task>) => {
    try {
      const { error } = await supabase
        .from('tasks')
        .update(updates as any)
        .eq('id', id)

      if (error) {
        set({ error: error.message })
        return
      }

      set(state => ({
        tasks: state.tasks.map(task => 
          task.id === id ? { ...task, ...updates } : task
        ),
        selectedTask: state.selectedTask?.id === id 
          ? { ...state.selectedTask, ...updates }
          : state.selectedTask
      }))
    } catch (error) {
      set({ error: 'Failed to update task' })
    }
  },

  updateTaskPosition: async (id: string, position: TaskPosition) => {
    try {
      const { error } = await supabase
        .from('tasks')
        .update({ 
          position_x: position.x, 
          position_y: position.y 
        } as any)
        .eq('id', id)

      if (error) {
        console.error('Database error updating position:', error)
        throw new Error(error.message)
      }

      // Update local state with exact values
      set(state => ({
        tasks: state.tasks.map(task => 
          task.id === id 
            ? { ...task, position_x: position.x, position_y: position.y }
            : task
        )
      }))
      
      console.log(`Updated task ${id} position to:`, position)
    } catch (error) {
      console.error('Failed to update task position:', error)
      throw error // Re-throw to handle in component
    }
  },

  deleteTask: async (id: string) => {
    try {
      const { error } = await supabase
        .from('tasks')
        .delete()
        .eq('id', id)

      if (error) {
        set({ error: error.message })
        return
      }

      set(state => ({
        tasks: state.tasks.filter(task => task.id !== id),
        selectedTask: state.selectedTask?.id === id ? null : state.selectedTask
      }))
    } catch (error) {
      set({ error: 'Failed to delete task' })
    }
  },

  selectTask: (task: Task | null) => {
    set({ selectedTask: task })
  },

  setTasks: (tasks: Task[]) => {
    set({ tasks })
  },

  addTask: (task: Task) => {
    set(state => ({ tasks: [task, ...state.tasks] }))
  },

  removeTask: (id: string) => {
    set(state => ({
      tasks: state.tasks.filter(task => task.id !== id),
      selectedTask: state.selectedTask?.id === id ? null : state.selectedTask
    }))
  },
}))