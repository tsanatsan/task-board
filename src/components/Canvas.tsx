import React, { useRef, useCallback, useEffect } from 'react'
import { DraggableSticker } from './DraggableSticker'
import { useTasksStore } from '../stores/tasks'

export const Canvas: React.FC = () => {
  const canvasRef = useRef<HTMLDivElement>(null)
  const { tasks, selectTask, updateTaskPosition } = useTasksStore()

  // Восстанавливаем стикеры, которые ушли за экран
  useEffect(() => {
    const recoverOffScreenStickers = async () => {
      const stickerWidth = 200
      const stickerHeight = 150
      const maxX = window.innerWidth - stickerWidth
      const maxY = window.innerHeight - stickerHeight
      
      for (const task of tasks) {
        let needsUpdate = false
        let newX = task.position_x
        let newY = task.position_y
        
        // Проверяем границы и корректируем позицию
        if (task.position_x < 0 || task.position_x > maxX) {
          newX = Math.max(0, Math.min(task.position_x, maxX))
          needsUpdate = true
        }
        
        if (task.position_y < 0 || task.position_y > maxY) {
          newY = Math.max(0, Math.min(task.position_y, maxY))
          needsUpdate = true
        }
        
        if (needsUpdate) {
          console.log(`Recovering sticker ${task.id} from (${task.position_x}, ${task.position_y}) to (${newX}, ${newY})`)
          await updateTaskPosition(task.id, { x: newX, y: newY })
        }
      }
    }
    
    if (tasks.length > 0) {
      recoverOffScreenStickers()
    }
  }, [tasks.length, updateTaskPosition]) // Запускаем только при изменении количества задач

  const handleCanvasClick = useCallback((e: React.MouseEvent) => {
    // Only close task selection if clicking on empty canvas
    if (e.target === e.currentTarget) {
      selectTask(null)
    }
  }, [selectTask])

  return (
    <div
      ref={canvasRef}
      className="canvas-container relative w-full h-full bg-gradient-to-br from-slate-50 to-slate-100 overflow-hidden"
      onClick={handleCanvasClick}
      style={{
        minHeight: '100vh',
        minWidth: '100vw'
      }}
    >
      
      {/* Tasks */}
      {tasks.map((task) => (
        <DraggableSticker
          key={task.id}
          task={task}
          onSelect={selectTask}
        />
      ))}
      
      {/* Empty state */}
      {tasks.length === 0 && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center text-gray-500">
            <div className="text-6xl mb-4">📝</div>
            <h3 className="text-xl font-medium mb-2">No tasks yet</h3>
            <p className="text-sm">Create your first sticky note task!</p>
          </div>
        </div>
      )}
    </div>
  )
}