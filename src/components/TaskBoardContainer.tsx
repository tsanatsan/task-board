import React, { useEffect, useCallback } from 'react'
import { TaskBoard } from './TaskBoard'
import { ControlPanel } from './ControlPanel'
import { useUIStore } from '../stores/ui'

export const TaskBoardContainer: React.FC = () => {
  const { isTaskModalOpen, setControlPanelVisible } = useUIStore()

  const handleControlAreaEnter = useCallback(() => {
    setControlPanelVisible(true)
  }, [setControlPanelVisible])

  const handleControlAreaLeave = useCallback(() => {
    setControlPanelVisible(false)
  }, [setControlPanelVisible])

  return (
    <div className="h-screen w-screen relative bg-gray-50 overflow-hidden">
      <TaskBoard />
      
      {/* Control panel hover area */}
      <div 
        className="absolute bottom-0 left-0 right-0 h-20 z-10"
        onMouseEnter={handleControlAreaEnter}
        onMouseLeave={handleControlAreaLeave}
      />
      
      <ControlPanel />
    </div>
  )
}