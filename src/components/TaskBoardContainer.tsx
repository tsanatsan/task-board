import React, { useEffect, useCallback } from 'react'
import { TaskBoard } from './TaskBoard'
import { ControlPanel } from './ControlPanel'
import { TaskModal } from './TaskModal'
import { useTasksStore } from '../stores/tasks'
import { useUIStore } from '../stores/ui'

export const TaskBoardContainer: React.FC = () => {
  const { fetchTasks, selectedTask, error } = useTasksStore()
  const { isTaskModalOpen, setControlPanelVisible } = useUIStore()

  useEffect(() => {
    fetchTasks()
  }, [fetchTasks])

  const handleControlAreaEnter = useCallback(() => {
    setControlPanelVisible(true)
  }, [setControlPanelVisible])

  const handleControlAreaLeave = useCallback(() => {
    setControlPanelVisible(false)
  }, [setControlPanelVisible])

  return (
    <div className="h-screen w-screen relative bg-gray-50 overflow-hidden">
      {/* Error display */}
      {error && (
        <div className="absolute top-4 left-4 right-4 bg-red-50 border border-red-300 text-red-700 px-4 py-3 rounded-lg z-50">
          {error}
        </div>
      )}
      
      <TaskBoard />
      
      {/* Control panel hover area */}
      <div 
        className="absolute bottom-0 left-0 right-0 h-20 z-10"
        onMouseEnter={handleControlAreaEnter}
        onMouseLeave={handleControlAreaLeave}
      />
      
      <ControlPanel />
      {(selectedTask || isTaskModalOpen) && <TaskModal />}
    </div>
  )
}