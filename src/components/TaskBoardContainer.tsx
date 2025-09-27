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
      
      {/* Control panel hover area - еще больше увеличенная область */}
      <div 
        className="absolute bottom-0 left-0 right-0 z-10"
        onMouseEnter={handleControlAreaEnter}
        onMouseLeave={handleControlAreaLeave}
        style={{
          height: '200px', // Увеличено с 128px до 200px - почти четверть экрана
          background: 'transparent',
          // Более плавная эллиптическая область срабатывания
          clipPath: 'ellipse(90% 100% at 50% 100%)'
        }}
      />
      
      <ControlPanel />
    </div>
  )
}