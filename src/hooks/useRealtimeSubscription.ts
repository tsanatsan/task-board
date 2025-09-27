import { useEffect, useRef } from 'react'
import { useTasksStore } from '../stores/tasks'
import { useAuthStore } from '../stores/auth'
import { supabase } from '../lib/supabase'
import { Task } from '../types'
import { RealtimeChannel } from '@supabase/supabase-js'

export const useRealtimeSubscription = () => {
  const { user } = useAuthStore()
  const { addTask, removeTask, setTasks } = useTasksStore()
  const channelRef = useRef<RealtimeChannel | null>(null)

  useEffect(() => {
    if (!user) return

    // Create a channel for real-time updates
    const channel = supabase
      .channel('tasks_channel')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'tasks',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          console.log('Task inserted:', payload)
          const newTask = payload.new as Task
          addTask(newTask)
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'tasks',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          console.log('Task updated:', payload)
          const updatedTask = payload.new as Task
          // Update tasks in store
          useTasksStore.getState().setTasks(
            useTasksStore.getState().tasks.map(task => 
              task.id === updatedTask.id ? updatedTask : task
            )
          )
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'tasks',
          filter: `user_id=eq.${user.id}`
        },
        (payload) => {
          console.log('Task deleted:', payload)
          const deletedTask = payload.old as Task
          removeTask(deletedTask.id)
        }
      )

    // Subscribe to the channel
    channel.subscribe((status) => {
      console.log('Realtime subscription status:', status)
    })

    channelRef.current = channel

    // Cleanup function
    return () => {
      if (channelRef.current) {
        channelRef.current.unsubscribe()
        channelRef.current = null
      }
    }
  }, [user, addTask, removeTask, setTasks])

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (channelRef.current) {
        channelRef.current.unsubscribe()
      }
    }
  }, [])
}